package com.project.uber.repository;

import com.project.uber.model.Driver;
import com.project.uber.model.Vehicle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VehicleRepository extends JpaRepository<Vehicle, Long> {
    Vehicle findByBrand(String Brand);
}