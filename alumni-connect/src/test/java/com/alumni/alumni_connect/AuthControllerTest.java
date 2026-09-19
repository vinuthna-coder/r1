package com.alumni.alumni_connect;

import com.alumni.alumni_connect.config.*;
import com.alumni.alumni_connect.controller.*;
import com.alumni.alumni_connect.dto.*;
import com.alumni.alumni_connect.entity.*;
import com.alumni.alumni_connect.exception.*;
import com.alumni.alumni_connect.repository.*;
import com.alumni.alumni_connect.security.*;
import com.alumni.alumni_connect.service.*;

import org.junit.jupiter.api.Test;

import org.mockito.Mockito;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

class AuthControllerTest {

    @Test
    void loginShouldWaitForApprovalWhenUserIsPending() {

        // Arrange

        AuthService authService =
                Mockito.mock(AuthService.class);

        AuthController controller =
                new AuthController(
                        authService
                );

        User existingUser =
                new User();

        existingUser.setEmail("student@gmail.com");
        existingUser.setRole("STUDENT");
        existingUser.setStatus("PENDING");
        existingUser.setPassword("encodedPassword");

        User loginUser =
                new User();

        loginUser.setEmail("student@gmail.com");
        loginUser.setRole("STUDENT");
        loginUser.setPassword("password123");

        when(authService.login(loginUser)).thenReturn("WAIT_APPROVAL");

        // Act

        Object result =
                controller.login(loginUser);

        // Assert

        assertEquals(
                "WAIT_APPROVAL",
                result
        );
    }
}
