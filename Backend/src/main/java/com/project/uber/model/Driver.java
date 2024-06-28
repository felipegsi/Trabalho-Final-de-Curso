package com.project.uber.model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.time.LocalDate;

@EqualsAndHashCode(callSuper = true)
@Entity
@Table(name = "drivers")
@Data
public class Driver extends User {
    //@Lob
    // @Column(name = "criminalRecord")//estava dando erro aqui por causa do tipo de dado
    // private byte[] criminalRecord; // Confirmado como byte[] para armazenar uma imagem
    @Column(name = "salary")
    private double salary; // Alterado para double

    @Column(name = "is_online")
    @JsonProperty(value = "is_online", access = JsonProperty.Access.WRITE_ONLY, defaultValue = "false")
    private Boolean isOnline = false; // Offline por padrão
    @Column(name = "is_busy")
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY, defaultValue = "false")
    private Boolean isBusy = false; // Indica se o motorista está ocupado com um pedido

    @OneToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "vehicle_id")
    @JsonBackReference
    private Vehicle vehicle;

    @Column(name = "location")
    private String location;


    public Driver() {
    }

    public Driver(String name, String email, String password, String birthdate,
                  String phoneNumber, int taxPayerNumber,
                  String street, String city,  String postalCode,
                  double salary, Vehicle vehicle, String location) {// esses ultimos 3 atributos nao estao no Driver
        super(name, email, password, birthdate, phoneNumber,
                taxPayerNumber, street, city, postalCode);
        this.salary = salary;
        this.vehicle = vehicle;
        this.location = location;
    }

    @Override
    public String toString() {
        return "Driver{" +
                "user=" + super.toString() +
                ", salary=" + salary +
                ", isOnline=" + isOnline +
                ", isBusy=" + isBusy +
                ", vehicleId=" + (vehicle != null ? vehicle.getId() : "No vehicle") +
                ", location='" + location;
    }
}
