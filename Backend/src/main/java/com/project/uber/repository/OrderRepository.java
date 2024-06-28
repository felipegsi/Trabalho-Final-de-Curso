package com.project.uber.repository;


import com.project.uber.model.Order;
import org.jetbrains.annotations.NotNull;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByClientId(Long clientId);
    List<Order> findByDriverId(Long driverId);


   // @NotNull
   // Optional<Order> findById(@NotNull Long id);

}
