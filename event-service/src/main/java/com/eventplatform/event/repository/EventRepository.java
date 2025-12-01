package com.eventplatform.event.repository;

import com.eventplatform.event.entity.Event;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface EventRepository extends JpaRepository<Event, Long> {

       // Find events by organizer
       List<Event> findByOrganizerId(Long organizerId);

       // Find events by status
       List<Event> findByStatus(String status);

       // Find published events
       List<Event> findByStatusOrderByStartDateAsc(String status);
       
       // Find events by status with pagination
       Page<Event> findByStatusOrderByStartDateAsc(String status, Pageable pageable);

       // Search events by title or description
       @Query("SELECT e FROM Event e WHERE " +
                     "(e.title ILIKE '%' || :searchTerm || '%' OR " +
                     "e.description ILIKE '%' || :searchTerm || '%') AND " +
                     "e.status = :status")
       List<Event> searchPublishedEvents(@Param("searchTerm") String searchTerm,
                     @Param("status") String status);

       // Find events by city
       List<Event> findByCityAndStatus(String city, String status);

       // Find events by event type
       List<Event> findByEventTypeAndStatus(String eventType, String status);

       // Find upcoming events
       @Query("SELECT e FROM Event e WHERE e.startDate > :currentDate AND e.status = :status ORDER BY e.startDate ASC")
       List<Event> findUpcomingEvents(@Param("currentDate") LocalDateTime currentDate,
                     @Param("status") String status);

       // Find events within date range
       @Query("SELECT e FROM Event e WHERE e.startDate BETWEEN :startDate AND :endDate AND e.status = :status")
       List<Event> findEventsInDateRange(@Param("startDate") LocalDateTime startDate,
                     @Param("endDate") LocalDateTime endDate,
                     @Param("status") String status);

       // Simplified JPQL query - default to published events if no filters
       @Query("SELECT e FROM Event e WHERE " +
                      "(:searchTerm IS NULL OR :searchTerm = '' OR LOWER(e.title) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR LOWER(e.description) LIKE LOWER(CONCAT('%', :searchTerm, '%'))) AND " +
                      "(:city IS NULL OR e.city = :city) AND " +
                      "(:eventType IS NULL OR e.eventType = :eventType) AND " +
                      "(:status IS NULL OR e.status = :status) AND " +
                      "(:startDate IS NULL OR e.startDate >= :startDate) AND " +
                      "(:endDate IS NULL OR e.endDate <= :endDate) " +
                      "ORDER BY e.startDate ASC")
       Page<Event> findEventsWithFilters(@Param("searchTerm") String searchTerm,
                     @Param("city") String city,
                     @Param("eventType") String eventType,
                     @Param("status") String status,
                     @Param("startDate") LocalDateTime startDate,
                     @Param("endDate") LocalDateTime endDate,
                     Pageable pageable);
}
