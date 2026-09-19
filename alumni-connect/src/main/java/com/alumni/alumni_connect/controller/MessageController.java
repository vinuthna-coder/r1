package com.alumni.alumni_connect.controller;

import com.alumni.alumni_connect.config.*;
import com.alumni.alumni_connect.controller.*;
import com.alumni.alumni_connect.dto.*;
import com.alumni.alumni_connect.entity.*;
import com.alumni.alumni_connect.exception.*;
import com.alumni.alumni_connect.repository.*;
import com.alumni.alumni_connect.security.*;
import com.alumni.alumni_connect.service.*;

import org.springframework.http.HttpStatus;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.security.Principal;

@RestController
public class MessageController {

    private final MessageService messageService;

    public MessageController(
            MessageService messageService
    ) {

        this.messageService = messageService;
    }

    // =====================================
    // SEND MESSAGE
    // =====================================

    @MessageMapping("/chat")
    public void sendMessage(
            @Payload Message message,
            Principal principal
    ) {
        if (principal == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Authentication required");
        }
        messageService.sendMessage(message, principal.getName());
    }

    // =====================================
    // GET CONVERSATION
    // =====================================

    @GetMapping("/messages/conversation")
    public List<Message> getConversation(

            @RequestParam String sender,

            @RequestParam String receiver

    ) {

        String authenticatedEmail =
                SecurityContextHolder
                        .getContext()
                        .getAuthentication()
                        .getName();

        try {
            return messageService.getConversation(authenticatedEmail, sender, receiver);
        } catch (IllegalArgumentException exception) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You are not part of this conversation");
        }
    }

    // =====================================
    // GET INBOX CONVERSATIONS
    // =====================================

    @GetMapping("/conversations")
    public List<ConversationDTO> getConversations() {

        return messageService.getConversations();
    }
}
