package com.project.uber.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;


import java.util.Collection;

//modelmapper -> mapear os objetos
@MappedSuperclass
@NoArgsConstructor
@Data
public abstract class User implements UserDetails {
    @Id
    @GeneratedValue
    private Long id;
    @Column(nullable = false, length = 100)
    private String name;
    @Column(nullable = false, unique = true, length = 100)
    private String email;
    @Column(nullable = false)
    private String password;
    @Column(nullable = false, unique = true)
    private String phoneNumber;
    @Column(nullable = false, unique = true)
    private int taxPayerNumber;
    @Column(nullable = false, length = 100)
    private String street;
    @Column(nullable = false, length = 50)
    private String city;
    @Column(nullable = false, length = 20)
    private int postalCode;

    //@Transient //saved in the database as a blob, but not as a column, only saved in the front-end
    //private byte[] profileImage;

    //@Column(nullable = false)
    //private RoleEnum role;

    public User(String name, String email, String password,
                String phoneNumber, int taxPayerNumber,
                String street, String city, int postalCode) {
        this.name = name;
        this.email = email;
        this.password = password;
        this.phoneNumber = phoneNumber;
        this.taxPayerNumber = taxPayerNumber;
        this.street = street;
        this.city = city;
        this.postalCode = postalCode;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return null;
    }

    @Override
    public String getPassword() {
        return this.password;
    }

    @Override
    public String getUsername() {
        return this.email;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }

    //getPrincipal() -> retorna o usuário logado


}