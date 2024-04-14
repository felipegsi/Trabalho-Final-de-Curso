package com.project.uber.dtos;


public record ClientDto(
        String name,
        String email,
        String password,
        String phoneNumber,
        int taxPayerNumber,
        String street,
        String city,
        int postalCode

) {
}
