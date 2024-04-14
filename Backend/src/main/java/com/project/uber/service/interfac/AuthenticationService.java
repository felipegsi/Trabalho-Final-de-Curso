package com.project.uber.service.interfac;

import org.springframework.security.core.userdetails.UserDetailsService;

import com.project.uber.dtos.AuthDto;

public interface AuthenticationService extends UserDetailsService {
    public String getClientTokenJwt(AuthDto authDto);
    public String getClientEmailFromToken(String token);
    public Long getClientIdFromToken(String token);
    public String getDriverTokenJwt(AuthDto authDto);
    public String getDriverEmailFromToken(String token);
    public Long getDriverIdFromToken(String token);

}