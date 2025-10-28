package org.sid.compte_service;

import java.util.Date;
import org.sid.compte_service.entities.Compte;
import org.sid.compte_service.enums.TypeCompte;
import org.sid.compte_service.repositories.CompteRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class CompteServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(CompteServiceApplication.class, args);
    }

    @Bean
    CommandLineRunner start(CompteRepository compteRepository) {
        return args -> {
            compteRepository.save(new Compte(null, 98000, new Date(), TypeCompte.COURANT));
            compteRepository.save(new Compte(null, 12000, new Date(), TypeCompte.EPARGNE));
            compteRepository.save(new Compte(null, 2100, new Date(), TypeCompte.COURANT));

            compteRepository.findAll().forEach(cp -> {
                System.out.println(cp.getType());
                System.out.println(cp.getSolde());
            });
        };
    }
}