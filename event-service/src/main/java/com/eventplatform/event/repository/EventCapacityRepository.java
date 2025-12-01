package com.eventplatform.event.repository;

import com.eventplatform.event.entity.EventCapacity;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface EventCapacityRepository extends JpaRepository<EventCapacity, Long> {

    // Find capacity with pessimistic lock for concurrent updates
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT ec FROM EventCapacity ec WHERE ec.eventId = :eventId")
    EventCapacity findByEventIdWithLock(@Param("eventId") Long eventId);

    // Check if event has available capacity
    @Query("SELECT CASE WHEN ec.availableCapacity >= :quantity THEN true ELSE false END " +
           "FROM EventCapacity ec WHERE ec.eventId = :eventId")
    boolean hasAvailableCapacity(@Param("eventId") Long eventId, @Param("quantity") int quantity);

    // Get available capacity for an event
    @Query("SELECT ec.availableCapacity FROM EventCapacity ec WHERE ec.eventId = :eventId")
    Integer getAvailableCapacity(@Param("eventId") Long eventId);
}


