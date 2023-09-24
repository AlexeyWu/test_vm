<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the web site, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://wordpress.org/documentation/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );

/** Database username */
define( 'DB_USER', 'alex' );

/** Database password */
define( 'DB_PASSWORD', 'Otus#Linux2023' );

/** Database hostname */
define( 'DB_HOST', '192.168.10.30' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8mb4' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         '%Uh5.[~T9zn%ED8-cCmlV/._t)lL;@|:|nZZPnx1oQ:r#-vCW)&~]vrepYip`i{/' );
define( 'SECURE_AUTH_KEY',  'V&]K]UTY)?,LS%x<m}7-]0i%Q~WvJry1A$&E0$tw& c1@cppVxxF<:6l{#epF5T:' );
define( 'LOGGED_IN_KEY',    'xldLJ__+k5)S3v}!AY1S{>6W@qdVWI+z(Cm~S}FO91j4]2Jxh`}HK7S|psv!<fLM' );
define( 'NONCE_KEY',        'sB9UTRXihFR[,? Xac+W57P~AaC$SmH_PA:(h=}![:eQahfYacE>|eYrU^gfve+5' );
define( 'AUTH_SALT',        '{>P6Or+X?6a_9`*q/NHxt: ^Lu&4^2f4y`)*<sk[*x+ve`X^wA.Vcd3_C`%RK_1(' );
define( 'SECURE_AUTH_SALT', 'o#7*Pbn}le!V+wT(a$j4UHM+Y^y_$PZ]jloW19t(q?#+ti(XsP3pF,,^TxgHU6jt' );
define( 'LOGGED_IN_SALT',   ':E5i!+B#{~@ni#z~}f.iD7.07CJO&f~&#4L4U&HdK=52>~Rvd<n},hLyC@[ef!O/' );
define( 'NONCE_SALT',       '#_&3Dh4_53AhK~YR#*gyhq3O*gK[2EYtiS>D)^F&0dQ_p$h0L^V%=zmTM5Rys)BR' );

/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/documentation/article/debugging-in-wordpress/
 */
define( 'WP_DEBUG', false );

/* Add any custom values between this line and the "stop editing" line. */



/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';

