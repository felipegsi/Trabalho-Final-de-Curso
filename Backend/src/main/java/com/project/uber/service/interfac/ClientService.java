package com.project.uber.service.interfac;

import com.project.uber.dtos.ClientDto;
import com.project.uber.dtos.OrderDto;
import com.project.uber.model.Client;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public interface ClientService {


    // This method is used to save a new client. It first checks if a client with the same email already exists.
    // If the client already exists, it throws a BusinessException. Otherwise, it saves the new client in the database.
    ClientDto saveClient(Client newClient);

    void deleteClient(Long clientId);

    Client getClientById(Long clientId);

    Client getClientByEmail(String email);

    public List<OrderDto> getClientOrderHistory(Long clientId);

    void changePassword(Long clientId, String oldPassword, String newPassword);

    @Transactional
        //para garantir que as duas operações sejam executadas ou nenhuma
    ClientDto editProfile(Long clientId, ClientDto clientDto);

    ClientDto viewProfile(Long clientId);


    //quais outras funcionalidades o cliente pode ter?
    //criar um pedido - semi-implementado
    //verificar o histórico de pedidos - semi-implementado
    //deletar a conta - semi-implementado - *** apenas deletar se nao tiver pedido em pendente ***
    //mudar a senha - implementado
    //recuperar a senha
    //atualizar os dados
    //verificar os dados
    //verificar os pedidos

}
