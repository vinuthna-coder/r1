package com.alumni.alumni_connect;

import com.alumni.alumni_connect.config.*;
import com.alumni.alumni_connect.controller.*;
import com.alumni.alumni_connect.dto.*;
import com.alumni.alumni_connect.entity.*;
import com.alumni.alumni_connect.exception.*;
import com.alumni.alumni_connect.repository.*;
import com.alumni.alumni_connect.security.*;
import com.alumni.alumni_connect.service.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.UUID;

import org.springframework.transaction.annotation.Propagation;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.mock;

@SpringBootTest
@Transactional
class MessagingIntegrationTest {
    @Autowired private MessageService messageService;
    @Autowired private MessageRepository messageRepository;
    @Autowired private ConversationRepository conversationRepository;
    @Autowired private ConversationParticipantRepository participantRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private JwtUtil jwtUtil;
    @Autowired private StompJwtChannelInterceptor interceptor;
    @MockBean private SimpMessagingTemplate messagingTemplate;
    @MockBean private NotificationService notificationService;
    private final MessageChannel messageChannel = mock(MessageChannel.class);

    private User alice;
    private User bob;
    private User charlie;

    @BeforeEach
    void setUpUsers() {
        String suffix = UUID.randomUUID().toString();
        alice = createUser("message-alice-" + suffix + "@example.test");
        bob = createUser("message-bob-" + suffix + "@example.test");
        charlie = createUser("message-charlie-" + suffix + "@example.test");
    }

    @Test
    void validStompConnectEstablishesAuthenticatedPrincipal() {
        String token = jwtUtil.generateToken(alice.getEmail(), "STUDENT");
        StompHeaderAccessor accessor = connectAccessor("Bearer " + token);

        org.springframework.messaging.Message<?> authenticated = interceptor.preSend(
                MessageBuilder.createMessage(new byte[0], accessor.getMessageHeaders()), messageChannel);

        assertEquals(alice.getEmail(), StompHeaderAccessor.wrap(authenticated).getUser().getName());
    }

    @Test
    void missingOrInvalidStompJwtIsRejected() {
        assertThrows(IllegalArgumentException.class, () -> interceptor.preSend(
                MessageBuilder.createMessage(new byte[0], connectAccessor(null).getMessageHeaders()), messageChannel));
        assertThrows(IllegalArgumentException.class, () -> interceptor.preSend(
                MessageBuilder.createMessage(new byte[0], connectAccessor("Bearer invalid").getMessageHeaders()), messageChannel));
    }

    @Test
    void authenticatedSendPersistsAuthoritativeSenderConversationAndPrivateDelivery() {
        Message message = request(bob.getEmail(), "hello", null);
        message.setSenderEmail(charlie.getEmail()); // spoofed client field

        messageService.sendMessage(message, alice.getEmail());

        Message saved = messageRepository.findAll().stream().filter(m -> "hello".equals(m.getContent())).findFirst().orElseThrow();
        assertEquals(alice.getEmail(), saved.getSenderEmail());
        assertEquals(alice.getId(), saved.getSender().getId());
        assertNotNull(saved.getConversation());
        assertNotNull(saved.getConversation().getLastMessageAt());
        assertEquals("hello", saved.getContent());
        verify(messagingTemplate).convertAndSendToUser(eq(alice.getEmail()), eq("/queue/messages"), same(saved));
        verify(messagingTemplate).convertAndSendToUser(eq(bob.getEmail()), eq("/queue/messages"), same(saved));
    }

    @Test
    void nonParticipantAndUnknownConversationCannotPersistOrUpdateActivity() {
        messageService.sendMessage(request(bob.getEmail(), "first", null), alice.getEmail());
        Message first = messageRepository.findAll().stream().filter(m -> "first".equals(m.getContent())).findFirst().orElseThrow();
        Long conversationId = first.getConversationId();
        LocalDateTime activity = conversationRepository.findById(conversationId).orElseThrow().getLastMessageAt();
        long count = messageRepository.count();

        assertThrows(IllegalArgumentException.class, () ->
                messageService.sendMessage(request(bob.getEmail(), "forbidden", conversationId), charlie.getEmail()));
        assertThrows(IllegalArgumentException.class, () ->
                messageService.sendMessage(request(bob.getEmail(), "missing", Long.MAX_VALUE), alice.getEmail()));

        assertEquals(count, messageRepository.count());
        assertEquals(activity, conversationRepository.findById(conversationId).orElseThrow().getLastMessageAt());
        assertTrue(participantRepository.existsByConversation_IdAndUser_Id(conversationId, alice.getId()));
        assertTrue(participantRepository.existsByConversation_IdAndUser_Id(conversationId, bob.getId()));
        assertFalse(participantRepository.existsByConversation_IdAndUser_Id(conversationId, charlie.getId()));
    }

    @Test
    void oppositeDirectionFirstMessagesReuseOneCanonicalConversation() {
        messageService.sendMessage(request(bob.getEmail(), "from-alice", null), alice.getEmail());
        messageService.sendMessage(request(alice.getEmail(), "from-bob", null), bob.getEmail());

        Message aliceMessage = messageRepository.findAll().stream()
                .filter(m -> "from-alice".equals(m.getContent())).findFirst().orElseThrow();
        Message bobMessage = messageRepository.findAll().stream()
                .filter(m -> "from-bob".equals(m.getContent())).findFirst().orElseThrow();

        assertEquals(aliceMessage.getConversationId(), bobMessage.getConversationId());
        assertTrue(conversationRepository.findDirectConversation(
                Math.min(alice.getId(), bob.getId()), Math.max(alice.getId(), bob.getId())).isPresent());
        assertTrue(participantRepository.existsByConversation_IdAndUser_Id(
                aliceMessage.getConversationId(), alice.getId()));
        assertTrue(participantRepository.existsByConversation_IdAndUser_Id(
                aliceMessage.getConversationId(), bob.getId()));
    }

    @Test
    void normalizedConversationRetrievalRequiresParticipantAndKeepsLegacyCompatibilityIsolated() {
        Message legacy = new Message(alice.getEmail(), bob.getEmail(), "legacy", LocalDateTime.now().minusMinutes(1));
        messageRepository.save(legacy);
        messageService.sendMessage(request(bob.getEmail(), "normalized", null), alice.getEmail());

        assertEquals(2, messageService.getConversation(alice.getEmail(), alice.getEmail(), bob.getEmail()).size());
        assertThrows(IllegalArgumentException.class, () ->
                messageService.getConversation(charlie.getEmail(), alice.getEmail(), bob.getEmail()));
    }

    @Test
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    void concurrentFirstMessagesShareTheCanonicalConversation() throws Exception {
        ExecutorService executor = Executors.newFixedThreadPool(2);
        try {
            Future<?> fromAlice = executor.submit(() ->
                    messageService.sendMessage(request(bob.getEmail(), "concurrent-alice", null), alice.getEmail()));
            Future<?> fromBob = executor.submit(() ->
                    messageService.sendMessage(request(alice.getEmail(), "concurrent-bob", null), bob.getEmail()));
            fromAlice.get();
            fromBob.get();
        } finally {
            executor.shutdownNow();
        }

        Message aliceMessage = messageRepository.findAll().stream()
                .filter(m -> "concurrent-alice".equals(m.getContent())).findFirst().orElseThrow();
        Message bobMessage = messageRepository.findAll().stream()
                .filter(m -> "concurrent-bob".equals(m.getContent())).findFirst().orElseThrow();
        assertEquals(aliceMessage.getConversationId(), bobMessage.getConversationId());
        assertTrue(conversationRepository.findDirectConversation(
                Math.min(alice.getId(), bob.getId()), Math.max(alice.getId(), bob.getId())).isPresent());
    }

    private User createUser(String email) {
        User user = new User("Messaging Test", email, "not-used", "STUDENT", "APPROVED");
        return userRepository.save(user);
    }

    private Message request(String receiver, String content, Long conversationId) {
        Message message = new Message();
        message.setReceiverEmail(receiver);
        message.setContent(content);
        message.setConversationId(conversationId);
        return message;
    }

    private StompHeaderAccessor connectAccessor(String authorization) {
        StompHeaderAccessor accessor = StompHeaderAccessor.create(StompCommand.CONNECT);
        if (authorization != null) accessor.setNativeHeader("Authorization", authorization);
        accessor.setLeaveMutable(true);
        return accessor;
    }
}

