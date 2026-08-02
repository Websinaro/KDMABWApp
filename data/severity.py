def get_alert_level(weather_code: int, rain_probability: float, wind_speed: float) -> str:
	if weather_code in (65, 67, 82, 96, 99) or rain_probability >= 90 or wind_speed >= 62:
		return "red"

	if weather_code in (63, 66, 80, 81, 95) or rain_probability >= 70 or wind_speed >= 45:
		return "orange"

	if weather_code in (51, 53, 55, 56, 57, 61, 85, 86) or rain_probability >= 40 or wind_speed >= 30:
		return "yellow"

	return "green"
