<?php
/**
 * Piwik - free/libre analytics platform
 *
 * @link http://piwik.org
 * @license http://www.gnu.org/licenses/gpl-3.0.html GPL v3 or later
 */

// tiny script to get plugin version from plugin.json from a bash script
require_once __DIR__ . '/../../core/Version.php';

function getRequiredPiwikVersions($pluginJsonContents)
{
    $requiredPiwikVersion = '';
    if (isset($pluginJsonContents["require"]["piwik"])) {
        $requiredPiwikVersion = (string) $pluginJsonContents["require"]["piwik"];
    }

    $requiredVersions = explode(',', $requiredPiwikVersion);

    $versions = array();
    foreach ($requiredVersions as $required) {
        if (preg_match('{^(<>|!=|>=?|<=?|==?)\s*(.*)}', $required, $matches)) {
            $comparison = trim($matches[1]);
            $version = $matches[2];

            if (!preg_match("/^[^0-9]*(.*)/", $version)
                || empty($version)
            ) {
                // not a valid version number
                continue;
            }

            $versions[] = array(
                'comparison' => $comparison,
                'version' => $version
            );
        }
    }

    return $versions;
}

function getMinVersion(array $requiredVersions)
{
    $minVersion = '';

    foreach ($requiredVersions as $required) {
        $comparison = $required['comparison'];
        $version    = $required['version'];

        if (in_array($comparison, array('>=','>', '=='))) {
            if (empty($minVersion)) {
                $minVersion = $version;
            } elseif (version_compare($version, $minVersion, '<=')) {
                $minVersion = $version;
            }
        }
    }

    return $minVersion;
}
