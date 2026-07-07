package com.gdmec.campchannel.common.utils;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

@Component
public class JwtUtils {

    @Value("${jwt.secret}")
    private String secret;

    @Getter
    @Value("${jwt.expiration}")
    private Long expiration;

    @Getter
    @Value("${jwt.header}")
    private String header;

    @Getter
    @Value("${jwt.token-start-with}")
    private String tokenStartWith;

    private SecretKey getSigningKey() {
        byte[] keyBytes = this.secret.getBytes();
        return Keys.hmacShaKeyFor(keyBytes);
    }

    public String getUsernameFromToken(String token) {
        return getClaimFromToken(token, Claims::getSubject);
    }

    public Date getExpirationDateFromToken(String token) {
        return getClaimFromToken(token, Claims::getExpiration);
    }

    public <T> T getClaimFromToken(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = getAllClaimsFromToken(token);
        return claimsResolver.apply(claims);
    }

    private Claims getAllClaimsFromToken(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private Boolean isTokenExpired(String token) {
        final Date expirationDate = getExpirationDateFromToken(token);
        return expirationDate.before(new Date());
    }

    public String generateToken(String username, Map<String, Object> claims) {
        return Jwts.builder()
                .claims(claims)
                .subject(username)
                .issuedAt(new Date(System.currentTimeMillis()))
                .expiration(new Date(System.currentTimeMillis() + expiration * 1000L))
                .signWith(getSigningKey(), Jwts.SIG.HS512)
                .compact();
    }

    public String generateToken(String username) {
        return generateToken(username, new HashMap<>());
    }

    public Boolean validateToken(String token, UserDetails userDetails) {
        final String username = getUsernameFromToken(token);
        return (username.equals(userDetails.getUsername()) && !isTokenExpired(token));
    }

    public Boolean isTokenAboutToExpire(String token) {
        try {
            final Date expirationDate = getExpirationDateFromToken(token);
            // If expires in less than 30 minutes
            return (expirationDate.getTime() - System.currentTimeMillis()) < 1800 * 1000L;
        } catch (Exception e) {
            return false;
        }
    }

    public String refreshToken(String token) {
        final Claims claims = getAllClaimsFromToken(token);
        final String username = claims.getSubject();
        Map<String, Object> newClaims = new HashMap<>(claims);
        newClaims.remove("sub");
        newClaims.remove("iat");
        newClaims.remove("exp");
        return generateToken(username, newClaims);
    }

    public Claims getClaimsFromExpiredToken(String token) {
        try {
            return getAllClaimsFromToken(token);
        } catch (io.jsonwebtoken.ExpiredJwtException e) {
            return e.getClaims();
        }
    }
}
