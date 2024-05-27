package com.project.uber.model;

import com.fasterxml.jackson.annotation.JsonManagedReference;
import com.project.uber.enums.Category;
import com.project.uber.enums.OrderStatus;
import com.project.uber.enums.PaymentMethod; // Certifique-se de que este enum está definido
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;

@Entity
@Data
@Table(name = "orders") //padrão consistente para nomes de tabelas e colunas, seja snake_case ou camelCase
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 150)
    private String origin;

    @Column(nullable = false, length = 150)
    private String destination;

    @Column(nullable = false) // Ajuste precision e scale conforme necessário ++
    private BigDecimal  value; // BigDecimal é adequado para valores monetários

    @Enumerated(EnumType.STRING)
    private OrderStatus status; // Supondo a existência de um enum OrderStatus

    @Column(nullable = false, updatable = false)
    @CreationTimestamp
    private LocalDate date; // Data de criação

    @Column(nullable = false, updatable = false)
    @CreationTimestamp
    private LocalTime time; // Hora de criação

    @Column(nullable = true, length = 500) // Ajuste o tamanho conforme necessário
    private String description;

    @Column(nullable = true, length = 1000) // Permita um feedback mais longo, se necessário
    private String feedback;

    @JsonManagedReference
    @ManyToOne
    @JoinColumn(name = "client_id") // Chave estrangeira na tabela 'orders'
    private Client client;

    @Column(nullable = false) // Permita um feedback ma is longo, se necessário
    @Enumerated(EnumType.STRING)
    private Category category;


    @ManyToOne
    @JoinColumn(name = "driver_id") // Define a coluna de chave estrangeira para Driver
    private Driver driver;


    //contructor
    public Order(String origin, String destination, BigDecimal  value,
                 OrderStatus status, LocalDate date, LocalTime time,
                 String description, String feedback, Client client, Category category) {
        this.origin = origin;
        this.destination = destination;
        this.value = value;
        this.status = status;
        this.date = date;
        this.time = time;
        this.description = description;
        this.feedback = feedback;
        this.client = client;
        this.category = category;
    }

    public Order() {
    }


}