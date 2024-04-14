package com.project.uber.service.interfac;

import com.project.uber.dtos.ClientDto;
import com.project.uber.dtos.OrderDto;
import com.project.uber.model.Client;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public interface ClientService {

    public ClientDto saveClient(ClientDto clientDto);

    public void deleteClient(Long clientId);

    Client getClientById(Long clientId);
    Client getClientByEmail(String email);

    public void changePassword(Long clientId, String oldPassword, String newPassword);

    @Transactional //para garantir que as duas operações sejam executadas ou nenhuma
    public ClientDto editProfile(Long clientId, ClientDto clientDto);

    public ClientDto viewProfile(Long clientId);


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
