   package org.springframework.samples.petclinic.customers.config;

   import org.springframework.context.annotation.Configuration;
   import org.springframework.security.config.annotation.web.builders.HttpSecurity;
   import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
   import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;

   @Configuration
   @EnableWebSecurity
   public class SecurityConfig extends WebSecurityConfigurerAdapter {

       @Override
       protected void configure(HttpSecurity http) throws Exception {
           http
               .csrf().disable()
               .authorizeRequests()
                   .antMatchers("/actuator/health", "/actuator/info").permitAll()
                   .antMatchers("/actuator/**").hasRole("ADMIN")
                   .antMatchers("/owners/**", "/petTypes").permitAll()
                   .anyRequest().authenticated()
               .and()
               .httpBasic();
       }
   }