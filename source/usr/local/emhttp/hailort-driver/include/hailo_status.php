<?php
header('Content-Type: application/json');
$hailo_devices = json_decode(shell_exec("/usr/bin/hailostatus -json"), true);

$response = [];

foreach ($hailo_devices as $hailo_device) {
  if(isset($hailo_device['error'])) {
    $response[] = [
      'device_id' => $device_id,
      'error' => true,
    ];
    continue;
  }
  $device_id = str_replace('/', '_', $hailo_device['device']);
  $frequencyMHz = $hailo_device['device_information']['neural_network_core_clock_rate'] / 1000000;
  if($hailo_device['device_information']['supported_features']['current_monitoring'] == 'true' ) {
    $type = $hailo_device['power_measurements']['type'];
    if($type === 'shunt_voltage' || $type === 'bus_voltage') {
      $units = 'mV';
    } elseif($type === 'power' || $type === 'auto') {
      $units = 'W';
    } else {
      $units = 'mW';
    }
    $power = round($hailo_device['power_measurements']['value'], 2) . ' ' . $units;
  } else {
    $power = 'N/A';
  }
  $response[] = [
    'device_id' => $device_id,
    'frequencyMHz' => $frequencyMHz . ' MHz',
    'power' => $power,
    'temp_s0' => round($hailo_device['chip_temperature']['s0'], 2) . ' °C' ?? 'N/A',
    'temp_s1' => round($hailo_device['chip_temperature']['s1'], 2) . ' °C' ?? 'N/A',
  ];
}

echo json_encode($response);
?>
