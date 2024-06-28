package com.project.uber;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.TimeZone;

@SpringBootApplication
public class UberDeMercadoriasTfcApplication {
    public static void main(String[] args) {
        // Define o fuso horário padrão para Lisboa
        TimeZone.setDefault(TimeZone.getTimeZone("Europe/Lisbon"));
        SpringApplication.run(UberDeMercadoriasTfcApplication.class, args);
    }
}
