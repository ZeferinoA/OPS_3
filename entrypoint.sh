echo "enable-rcon=true" >> /data/server.properties
echo "rcon.password=${RCON_PASSWORD}" >> /data/server.properties
echo "rcon.port=25575" >> /data/server.properties
echo "motd=${MOTD}" >> /data/server.properties

# Start the Paper server with optimized flags (Aikar's Flags for memory management)
# Note: Paper requires the jar to be run from the /data directory so it downloads
# its libraries into the persistent volume, not the immutable container path.
cd /data
exec java -Xms1024M -Xmx1024M \
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:MaxGCPauseMillis=200 \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+DisableExplicitGC \
    -XX:+AlwaysPreTouch \
    -XX:G1NewSizePercent=30 \
    -XX:G1MaxNewSizePercent=40 \
    -XX:G1HeapRegionSize=8M \
    -XX:G1ReservePercent=20 \
    -XX:G1HeapWastePercent=5 \
    -XX:G1MixedGCCountTarget=4 \
    -XX:InitiatingHeapOccupancyPercent=15 \
    -XX:G1MixedGCLiveThresholdPercent=90 \
    -XX:G1RSetUpdatingPauseTimePercent=5 \
    -XX:SurvivorRatio=32 \
    -XX:+PerfDisableSharedMem \
    -XX:MaxTenuringThreshold=1 \
    -Dusing.aikars.flags=https://mcflags.emc.gs \
    -Daikars.new.flags=true \
    -jar /opt/minecraft/paper.jar nogui
                                    