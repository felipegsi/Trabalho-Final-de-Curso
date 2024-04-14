package com.project.uber.configuration;


import com.project.uber.model.Client;
import com.project.uber.model.Driver;
import com.project.uber.repository.ClientRepository;
import com.project.uber.repository.DriverRepository;
import com.project.uber.service.interfac.AuthenticationService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;


import java.io.IOException;

@Component
public class SecurityFilter extends OncePerRequestFilter {
    @Autowired
    private AuthenticationService authenticationService;

    @Autowired
    private ClientRepository clientRepository;

    @Autowired
    private DriverRepository driverRepository; // Adicione um repositório para Driver

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String token = extractTokeHeader(request);

        if (token != null) {
            String email = authenticationService.getClientEmailFromToken(token);
            Client client = clientRepository.findByEmail(email);
            Driver driver = driverRepository.findByEmail(email); // Carregue o Driver pelo email

            if (client != null) {
                var autentication = new UsernamePasswordAuthenticationToken(client, null, client.getAuthorities());
                SecurityContextHolder.getContext().setAuthentication(autentication);
            } else if (driver != null) {
                var autentication = new UsernamePasswordAuthenticationToken(driver, null, driver.getAuthorities());
                SecurityContextHolder.getContext().setAuthentication(autentication);
            }
        }

        filterChain.doFilter(request, response);
    }

    public String extractTokeHeader(HttpServletRequest request) {
        var authHeader = request.getHeader("Authorization");

        if (authHeader == null) {
            return null;
        }

        if (!authHeader.split(" ")[0].equals("Bearer")) {
            return  null;
        }

        return authHeader.split(" ")[1];
    }
}