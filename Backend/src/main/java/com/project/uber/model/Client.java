package com.project.uber.model;

import java.time.LocalDate;
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
    @OneToMany(mappedBy = "client", cascade = CascadeType.ALL)// mappedBy = "client" indica que a relação é bidirecional
    private List<Order> orders;

    public Client(String name, String email, String password, String birthdate,
                  String phoneNumber, int taxPayerNumber, String street,
                  String city, String postalCode) {
        super(name, email, password, birthdate, phoneNumber,
                taxPayerNumber, street, city, postalCode);
    }

}
