package com.project.uber.repository;
import com.project.uber.enums.Category;
import com.project.uber.enums.VehicleType;
import com.project.uber.model.Client;
import com.project.uber.model.Driver;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DriverRepository extends JpaRepository<Driver, Long> {
    Driver findByEmail(String email);
    Driver findByPhoneNumber(String phoneNumber);
    Driver findByTaxPayerNumber(int taxPayerNumber);
    @Query("SELECT d FROM Driver d WHERE d.isOnline = true AND d.isBusy = false") // Query to find available drivers
    List<Driver> findAvailableDrivers();
    @Query("SELECT d FROM Driver d WHERE d.vehicle.category = :category AND d.isOnline = true AND d.isBusy = false")
    List<Driver> findAvailableDriversByVehicleType(Category category);
}