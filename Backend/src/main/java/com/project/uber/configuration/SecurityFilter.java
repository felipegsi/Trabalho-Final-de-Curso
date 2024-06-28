package com.project.uber.configuration;
import com.project.uber.infra.exceptions.BusinessException;
import com.project.uber.model.Client;
import com.project.uber.model.Driver;
import com.project.uber.repository.ClientRepository;
import com.project.uber.repository.DriverRepository;
import com.project.uber.service.interfac.AuthenticationService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.jetbrains.annotations.NotNull;
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
        try {
            String token = extractTokeHeader(request);

            if (token != null) {
                String email = authenticationService.getClientEmailFromToken(token);
                Client client = clientRepository.findByEmail(email);
                Driver driver = driverRepository.findByEmail(email);

                if (client != null) {
                    var authentication = new UsernamePasswordAuthenticationToken(client, null, client.getAuthorities());
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                } else if (driver != null) {
                    var authentication = new UsernamePasswordAuthenticationToken(driver, null, driver.getAuthorities());
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            }

            filterChain.doFilter(request, response);
        } catch (BusinessException ex) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Token expired or invalid: " + ex.getMessage());
        }
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