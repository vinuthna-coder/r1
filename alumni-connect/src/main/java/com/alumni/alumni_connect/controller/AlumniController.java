package com.alumni.alumni_connect.controller;

import com.alumni.alumni_connect.config.*;
import com.alumni.alumni_connect.controller.*;
import com.alumni.alumni_connect.dto.*;
import com.alumni.alumni_connect.entity.*;
import com.alumni.alumni_connect.exception.*;
import com.alumni.alumni_connect.repository.*;
import com.alumni.alumni_connect.security.*;
import com.alumni.alumni_connect.service.*;

import org.springframework.web.bind.annotation.*;

import java.util.List;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;

@RestController

@RequestMapping("/alumni")

@CrossOrigin(origins = "http://localhost:4200")

public class AlumniController {

    private final UserRepository repository;
    private final PasswordEncoder passwordEncoder;

    public AlumniController(
            UserRepository repository, PasswordEncoder passwordEncoder
    ) {
        this.repository = repository;
        this.passwordEncoder = passwordEncoder;
    }

    // =====================================================
    // GET ALL APPROVED ALUMNI
    // =====================================================

    @GetMapping
    public List<User> getAllApprovedAlumni() {

        return repository.findByRoleAndStatus(
                "ALUMNI",
                "APPROVED"
        );
    }

    // =====================================================
    // ADD ALUMNI
    // =====================================================

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public User addAlumni(
            @RequestBody User alumni
    ) {

        alumni.setRole("ALUMNI");

        alumni.setStatus("PENDING");

        if (alumni.getPassword() == null || alumni.getPassword().isBlank()) {
            throw new IllegalArgumentException("Password is required");
        }
        alumni.setPassword(passwordEncoder.encode(alumni.getPassword()));

        return repository.save(alumni);
    }

    // =====================================================
    // GET APPROVED ALUMNI
    // =====================================================

    @GetMapping("/approved")
    public List<User> getApprovedAlumni() {

        return repository.findByRoleAndStatus(
                "ALUMNI",
                "APPROVED"
        );
    }

    // =====================================================
    // DELETE ALUMNI
    // =====================================================

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public void deleteAlumni(
            @PathVariable Long id
    ) {

        repository.deleteById(id);
    }

    // =====================================================
    // APPROVE ALUMNI
    // =====================================================

    @PutMapping("/approve/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public User approveAlumni(
            @PathVariable Long id
    ) {

        User alumni =
                repository.findById(id)
                        .orElseThrow();

        alumni.setStatus("APPROVED");

        return repository.save(alumni);
    }
}

