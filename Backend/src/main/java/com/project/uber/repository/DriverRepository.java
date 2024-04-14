package com.project.uber.repository;
import com.project.uber.model.Client;
import com.project.uber.model.Driver;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;


@Repository
public interface DriverRepository extends JpaRepository<Driver, Long> {
    Driver findByEmail(String email);
    Optional<Driver> findByName(String name);
    @Query("SELECT d FROM Driver d WHERE d.isOnline = true")
    List<Driver> findAvailableDrivers();

}