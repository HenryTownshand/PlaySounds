Плагин проигрывает звуки указанные в конфиге в радиусе от игрока.
Есть возможность воспроизводить звуки из меню или быстрой командой(например для бинда).

пример бинда:
bind ALT "sm_ps #id"

id звуков указаны в скобках
![image](https://user-images.githubusercontent.com/40493521/205734902-5370fb51-25ea-49e4-af15-e287f7f1c965.png)

Предустановлено для примера 11 звуков:

"Sounds"
{
    "Назад ни шагу"        "serverTK/playsounds/nazad_ni_shagu.mp3"
    "Тихо работаем"        "serverTK/playsounds/tiho_rabotaem.mp3"
    "Прикрой 1"            "serverTK/playsounds/prikroy_1.mp3"
    "Прикрой 2"            "serverTK/playsounds/prikroy_2.mp3"
    "Внимательно"        "serverTK/playsounds/vnimaterlno.mp3"
    "Не выёбываемся"    "serverTK/playsounds/ne_viebivaemsya.mp3"
    "Устал"                "serverTK/playsounds/ustal.mp3"
    "Ааа, рука"            "serverTK/playsounds/a_ruka_bleat.mp3"
    "Маслину поймал"    "serverTK/playsounds/maslinu_poymal.mp3"
    "Нехороший человек"    "serverTK/playsounds/nehorosiy_chelovek.mp3"
    "Вижу уёбище"        "serverTK/playsounds/vizhu_uebishe.mp3"
}

для компиляции нужно:
https://hlmod.ru/threads/inc-cs-go-colors.46870/

Переменные	
// Тег плагина в чате
// -
// Default: "ГС"
sm_playsounds_tag "ГС"

// Время между воспроизведением звуков
// -
// Default: "10.0"
sm_playsounds_time "10.0"

// Начальная громкость звуков
// -
// Default: "20"
sm_playsounds_volume "20"
Команды	
!playsound - меню плагина
!ps #id или !gs #id - быстрое воспроизведение звука
Установка	
Раскидать всё по папкам.
Настроить конфиг addons/sourcemod/config/playsounds.cfg под себя
Если нужно, поправить в конфиге переменные

