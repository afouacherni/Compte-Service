package org.sid.compte_service.repositories;

import org.sid.compte_service.entities.Compte;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CompteRepository extends JpaRepository<Compte, Long> {
}