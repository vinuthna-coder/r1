package com.alumni.alumni_connect.service;

import com.alumni.alumni_connect.config.*;
import com.alumni.alumni_connect.controller.*;
import com.alumni.alumni_connect.dto.*;
import com.alumni.alumni_connect.entity.*;
import com.alumni.alumni_connect.exception.*;
import com.alumni.alumni_connect.repository.*;
import com.alumni.alumni_connect.security.*;
import com.alumni.alumni_connect.service.*;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;

@Service
public class AuthService {

    private final UserRepository repository;

    private final BCryptPasswordEncoder encoder;

    private final JwtUtil jwtUtil;

        private final StudentProfileRepository studentProfileRepository;

        private final AlumniProfileRepository alumniProfileRepository;

    public AuthService(
            UserRepository repository,
            BCryptPasswordEncoder encoder,
            JwtUtil jwtUtil,
            StudentProfileRepository studentProfileRepository,
            AlumniProfileRepository alumniProfileRepository
    ) {

        this.repository = repository;

        this.encoder = encoder;

        this.jwtUtil = jwtUtil;

        this.studentProfileRepository = studentProfileRepository;

        this.alumniProfileRepository = alumniProfileRepository;
    }

    // =====================================
    // SIGNUP
    // =====================================

        @Transactional
        public String signup(User user) {

        Optional<User> existing =
                repository.findByEmail(
                        user.getEmail()
                );

        if (existing.isPresent()) {

            return "Email already exists";
        }

        if (!"STUDENT".equalsIgnoreCase(user.getRole()) && !"ALUMNI".equalsIgnoreCase(user.getRole())) {
            throw new IllegalArgumentException("Only STUDENT and ALUMNI self-registration is allowed");
        }

        if (user.getPassword() == null || user.getPassword().length() < 8 || user.getPassword().length() > 128) {
            throw new IllegalArgumentException("Password does not meet requirements");
        }

        // ENCRYPT PASSWORD

        user.setPassword(
                encoder.encode(
                        user.getPassword()
                )
        );

        // WAIT FOR ADMIN APPROVAL

        user.setStatus("PENDING");

                User savedUser = repository.save(user);

                if ("STUDENT".equalsIgnoreCase(savedUser.getRole())) {
                        StudentProfile profile = new StudentProfile(savedUser);
                        profile.copyLegacyFields(savedUser);
                        studentProfileRepository.save(profile);
                } else if ("ALUMNI".equalsIgnoreCase(savedUser.getRole())) {
                        AlumniProfile profile = new AlumniProfile(savedUser);
                        profile.copyLegacyFields(savedUser);
                        alumniProfileRepository.save(profile);
                }

        return "Signup successful";
    }

    // =====================================
    // LOGIN
    // =====================================

    public Object login(User user) {

        Optional<User> optionalUser =
                repository.findByEmailAndRole(
                        user.getEmail(),
                        user.getRole()
                );

        if (optionalUser.isEmpty()) {

            return "Invalid credentials";
        }

        User existing =
                optionalUser.get();

        // CHECK APPROVAL

        if ("PENDING".equalsIgnoreCase(existing.getStatus())) {

            return "WAIT_APPROVAL";
        }

        if (!"APPROVED".equalsIgnoreCase(existing.getStatus())) {
            return "Invalid credentials";
        }

        // CHECK PASSWORD

        if (!encoder.matches(
                user.getPassword(),
                existing.getPassword()
        )) {

            return "Invalid credentials";
        }

        // GENERATE JWT

        return jwtUtil.generateToken(
                existing.getEmail(),
                existing.getRole()
        );
    }

    // =====================================
    // APPROVE USER
    // =====================================

    @PreAuthorize("hasRole('ADMIN')")
    public User approveUser(Long id) {

        User user =
                repository
                        .findById(id)
                        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        user.setStatus("APPROVED");

        return repository.save(user);
    }
}
