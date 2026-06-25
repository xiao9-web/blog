# ============================================
#  Halo 自定义构建 Dockerfile
#  从 halo/ 源码构建，用于个性化定制后的部署
#
#  用法:
#    1. 修改 halo/ 源码
#    2. docker build -t my-halo .
#    3. docker compose -f docker-compose.build.yml up -d
# ============================================

# ---- Stage 1: Build ----
FROM eclipse-temurin:21-jdk AS builder

WORKDIR /build

# 安装 Node.js (构建前端 UI)
RUN apt-get update && apt-get install -y nodejs npm && \
    npm install -g pnpm && rm -rf /var/lib/apt/lists/*

# 复制 Gradle 配置
COPY halo/gradle/ gradle/
COPY halo/gradlew halo/gradlew.bat halo/build.gradle halo/settings.gradle ./
COPY halo/gradle.properties ./
COPY halo/buildSrc/ buildSrc/

# 复制源码
COPY halo/api/ api/
COPY halo/platform/ platform/
COPY halo/application/ application/
COPY halo/ui/ ui/
COPY halo/hack/ hack/

# 构建（跳过测试加速）
RUN chmod +x gradlew && ./gradlew build -x test -x check

# ---- Stage 2: Extract JAR layers (Spring Boot) ----
FROM eclipse-temurin:21-jre AS extractor

WORKDIR /application
COPY --from=builder /build/application/build/libs/*.jar application.jar
RUN java -Djarmode=tools -jar application.jar extract --layers --destination extracted

# ---- Stage 3: Run ----
FROM eclipse-temurin:21-jre

LABEL maintainer="xiao9"
WORKDIR /application

COPY --from=extractor /application/extracted/dependencies/ ./
COPY --from=extractor /application/extracted/spring-boot-loader/ ./
COPY --from=extractor /application/extracted/snapshot-dependencies/ ./
COPY --from=extractor /application/extracted/application/ ./

ENV JVM_OPTS="" \
    HALO_WORK_DIR="/root/.halo2" \
    SPRING_CONFIG_LOCATION="optional:classpath:/;optional:file:/root/.halo2/" \
    TZ=Asia/Shanghai

RUN ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

EXPOSE 8090

ENTRYPOINT ["sh", "-c", "exec java ${JVM_OPTS} -jar application.jar \"$@\"", "--"]
