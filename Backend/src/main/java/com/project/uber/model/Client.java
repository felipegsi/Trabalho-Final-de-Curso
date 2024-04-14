package com.project.uber.model;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@Entity
@Table(name = "clients")
public class Client extends User {

    @JsonIgnore
    @OneToMany(mappedBy = "client", cascade = CascadeType.ALL)
    private List<Order> orders;

    public Client(String name, String email, String password,
                  String phoneNumber, int taxPayerNumber, String street,
                  String city, int postalCode) {
        super(name, email, password, phoneNumber, taxPayerNumber, street,
                city, postalCode);
    }



}
