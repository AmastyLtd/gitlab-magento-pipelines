<?php

$base = [
    'base-url' => 'http://localhost:8082',
    'db-host' => 'mysql',
    'db-user' => \getenv('MYSQL_USER'),
    'db-password' => \getenv('MYSQL_PASSWORD'),
    'db-name' => \getenv('MYSQL_DATABASE'),
    'db-prefix' => '',
    'backend-frontname' => 'backend',
    'admin-user' => 'admin',
    'admin-password' => 'yQDVChqA92DLuXW6',
    'admin-email' => \Magento\TestFramework\Bootstrap::ADMIN_EMAIL,
    'admin-firstname' => \Magento\TestFramework\Bootstrap::ADMIN_FIRSTNAME,
    'admin-lastname' => \Magento\TestFramework\Bootstrap::ADMIN_LASTNAME,
    'admin-use-security-key' => '0',
    'cleanup-database' => true,
    'session-save'  => 'db',
    'sales-order-increment-prefix' => time(),
    'use-secure'                   => '0',
    'use-rewrites'                 => '1',
    'language'                     => 'en_US',
    'timezone'                     => 'America/Chicago',
    'currency'                     => 'USD'
];

if (\getenv('ES_HOST')) {
    return \array_merge($base, [
        "search-engine" => "elasticsearch7",
        "elasticsearch-enable-auth" => false,
        "elasticsearch-host" => \getenv('ES_HOST'),
        "elasticsearch-port" => 9200
    ]);
}

return $base;

