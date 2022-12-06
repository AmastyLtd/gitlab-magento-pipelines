<?php

$base = [
    'db-host' => 'mysql',
    'db-user' => \getenv('MYSQL_USER'),
    'db-password' => \getenv('MYSQL_PASSWORD'),
    'db-name' => \getenv('MYSQL_DATABASE'),
    'db-prefix' => '',
    'backend-frontname' => 'backend',
    'admin-user' => \Magento\TestFramework\Bootstrap::ADMIN_NAME,
    'admin-password' => \Magento\TestFramework\Bootstrap::ADMIN_PASSWORD,
    'admin-email' => \Magento\TestFramework\Bootstrap::ADMIN_EMAIL,
    'admin-firstname' => \Magento\TestFramework\Bootstrap::ADMIN_FIRSTNAME,
    'admin-lastname' => \Magento\TestFramework\Bootstrap::ADMIN_LASTNAME,
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
