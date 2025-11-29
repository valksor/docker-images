<?php declare(strict_types = 1);

if (false === ($_ENV['DISABLE_PRELOAD'] ?? false)) {
    $preloadFile = $_ENV['PRELOAD_FILE'] ?? '/var/www/html/config/preload.php';

    if ('cli' !== PHP_SAPI && is_file($preloadFile)) {
        require $preloadFile;
    }
}