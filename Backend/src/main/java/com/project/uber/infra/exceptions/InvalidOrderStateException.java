package com.project.uber.infra.exceptions;

public class InvalidOrderStateException extends Exception {
    public InvalidOrderStateException(String message) {
        super(message);
    }
}