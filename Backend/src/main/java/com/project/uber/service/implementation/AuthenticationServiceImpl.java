package com.project.uber.service.implementation;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTCreationException;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.project.uber.model.Client;

import com.project.uber.model.Driver;
import com.project.uber.repository.ClientRepository;
import com.project.uber.repository.DriverRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

import com.project.uber.dtos.AuthDto;
import com.project.uber.service.interfac.AuthenticationService;

@Service
public class AuthenticationServiceImpl implements AuthenticationService {

    // The ClientRepository is autowired, which means Spring will automatically inject an instance of ClientRepository here.
    @Autowired
    private ClientRepository clientRepository;

    // The DriverRepository is autowired, which means Spring will automatically inject an instance of DriverRepository here.
    @Autowired
    private DriverRepository driverRepository;

    // This method is used to load a user by their email. It first tries to find a client with the given email.
// If no client is found, it tries to find a driver with the given email.
    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        UserDetails userDetails = clientRepository.findByEmail(email);
        if (userDetails == null) {
            userDetails = driverRepository.findByEmail(email);
        }
        return userDetails;
    }

    // This method is used to generate a JWT token for a client. It first finds the client with the given email,
// then calls another method to generate the token.
    @Override
    public String getClientTokenJwt(AuthDto authDto) {
        Client client = clientRepository.findByEmail(authDto.email());
        return generateClientTokenJwt(client);
    }

    // This method generates a JWT token for a client. It uses the client's email as the subject of the token,
// and includes the client's ID as a claim. The token is signed with a secret key and has an expiration date.
    public String generateClientTokenJwt(Client client) {
        try {
            Algorithm algorithm = Algorithm.HMAC256("my-secret");

            return JWT.create()
                    .withIssuer("auth-api")
                    .withSubject(client.getEmail())
                    .withClaim("clientId", client.getId())
                    .withExpiresAt(generateExpirationDate())
                    .sign(algorithm);
        } catch (JWTCreationException exception) {
            throw new RuntimeException("Error when trying to validate the token! Exception: " + exception.getMessage());
        }
    }

    // This method is used to get the client's email from a token. It verifies the token using the same secret key that was used to sign it.
    public String getClientEmailFromToken(String token) {
        try {
            Algorithm algorithm = Algorithm.HMAC256("my-secret");

            return JWT.require(algorithm)
                    .withIssuer("auth-api")
                    .build()
                    .verify(token)
                    .getSubject();

        } catch (JWTVerificationException exception) {
            throw new RuntimeException("Error when trying to validate the token! Exception: " + exception.getMessage());
        }
    }

    // This method is used to get the client's ID from a token. It verifies the token using the same secret key that was used to sign it.
    public Long getClientIdFromToken(String token) {

        if (token == null || token.isEmpty()) {
            throw new IllegalArgumentException("Token is null or empty");
        }
        try {
            Algorithm algorithm = Algorithm.HMAC256("my-secret");

            DecodedJWT jwt = JWT.require(algorithm)
                    .withIssuer("auth-api")
                    .build()
                    .verify(token);

            return jwt.getClaim("clientId").asLong();

        } catch (JWTVerificationException exception) {
            throw new RuntimeException("Error when trying to validate the token! Exception: " + exception.getMessage());
        }
    }

    // This method generates an expiration date for the JWT token. The token will expire 8 hours from the current time.
    private Instant generateExpirationDate() {
        return LocalDateTime.now()
                .plusHours(8)
                .toInstant(ZoneOffset.of("-03:00"));
    }

    // --------------------------- DRIVER ---------------------------

    // This method is used to generate a JWT token for a driver. It first finds the driver with the given email,
// then calls another method to generate the token.
    public String getDriverTokenJwt(AuthDto authDto) {
        Driver driver = driverRepository.findByEmail(authDto.email());
        return generateDriverTokenJwt(driver);
    }

    // This method generates a JWT token for a driver. It uses the driver's email as the subject of the token,
// and includes the driver's ID as a claim. The token is signed with a secret key and has an expiration date.
    public String generateDriverTokenJwt(Driver driver) {
        try {
            Algorithm algorithm = Algorithm.HMAC256("my-secret");

            return JWT.create()
                    .withIssuer("auth-api")
                    .withSubject(driver.getEmail())
                    .withClaim("driverId", driver.getId())
                    .withExpiresAt(generateExpirationDate())
                    .sign(algorithm);
        } catch (JWTCreationException exception) {
            throw new RuntimeException("Error when trying to validate the token! Exception: " + exception.getMessage());
        }
    }

    // This method is used to get the driver's email from a token. It verifies the token using the same secret key that was used to sign it.
    public String getDriverEmailFromToken(String token) {
        try {
            Algorithm algorithm = Algorithm.HMAC256("my-secret");

            return JWT.require(algorithm)
                    .withIssuer("auth-api")
                    .build()
                    .verify(token)
                    .getSubject();

        } catch (JWTVerificationException exception) {
            throw new RuntimeException("Error when trying to validate the token! Exception: " + exception.getMessage());
        }
    }

    // This method is used to get the driver's ID from a token. It verifies the token using the same secret key that was used to sign it.
    public Long getDriverIdFromToken(String token) {
        try {
            if (token == null || token.isEmpty()) {
                throw new IllegalArgumentException("Token is null or empty");
            }

            Algorithm algorithm = Algorithm.HMAC256("my-secret");

            DecodedJWT jwt = JWT.require(algorithm)
                    .withIssuer("auth-api")
                    .build()
                    .verify(token);

            return jwt.getClaim("driverId").asLong();

        } catch (JWTVerificationException exception) {
            throw new RuntimeException("Error when trying to validate the token! Exception: " + exception.getMessage());
        }
    }


}