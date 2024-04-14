package com.project.uber.infra.exceptions;

public class UnauthorizedDriverException extends Exception {
    public UnauthorizedDriverException(String message) {
        super(message);
    }
}