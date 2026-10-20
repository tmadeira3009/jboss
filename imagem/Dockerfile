# Imagem de laboratório — Red Hat UBI 9 + JBoss EAP 7.4 (domain mode)
# Base: UBI9 = imagem oficial gratuita da Red Hat (binário compatível com RHEL 9).
# O EAP 7.4 é certificado para RHEL 8/9 — RHEL 10 NÃO é suportado pelo EAP 7.4.
FROM registry.access.redhat.com/ubi9/ubi:latest

RUN dnf install -y java-11-openjdk-headless unzip python3 && dnf clean all

# O ZIP deve ser colocado nesta pasta antes do build (cada aluno baixa com sua conta Red Hat)
COPY jboss-eap-7.4.0.zip /tmp/eap.zip

RUN unzip -q /tmp/eap.zip -d /opt \
 && rm /tmp/eap.zip \
 && mv /opt/jboss-eap* /opt/eap \
 && sed -i 's/:127\.0\.0\.1}/:0.0.0.0}/g' /opt/eap/domain/configuration/host.xml \
 && useradd -r -u 185 jboss \
 && printf 'y\ny\n' | /opt/eap/bin/add-user.sh -u admin -p 'Eap@2026' \
 && if grep -q '^admin=' /opt/eap/standalone/configuration/mgmt-users.properties 2>/dev/null; then \
      cp -f /opt/eap/standalone/configuration/mgmt-users.properties \
            /opt/eap/domain/configuration/mgmt-users.properties; fi \
 && grep -q '^admin=' /opt/eap/domain/configuration/mgmt-users.properties \
 && cp -r /opt/eap/domain /opt/eap/simple \
 && sed -i 's/name="localhost"/name="simple"/' /opt/eap/simple/configuration/host.xml \
 && sed -z -i 's|<servers>.*</servers>||' /opt/eap/simple/configuration/host.xml \
 && sed -z -i 's|<server-groups>.*</server-groups>||' /opt/eap/simple/configuration/domain.xml \
 && chown -R jboss:jboss /opt/eap

USER jboss
WORKDIR /opt/eap

# 8080 apps · 9990 console/CLI · 9999 CLI nativa · 8009 AJP (mod_cluster) · 7600/7800 JGroups
EXPOSE 8080 9990 9999 8009 7600 7800

# Sobe o base dir "simple" (host renomeado, sem servers/server-groups) = estado da prova após a Tarefa 2
CMD ["/opt/eap/bin/domain.sh", "-Djboss.domain.base.dir=/opt/eap/simple"]
