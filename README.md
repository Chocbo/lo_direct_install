Скрипт **lo_direct_install.sh** появился во время обсуждения темы в личном блоге на [mintlinux.ru](http://www.mintlinux.ru/blogs/lin-lichka/ustanovka-openoffice-libreoffice-cherez-terminal.html) и он поможет вам установить самую свежую версию офисного пакета прямо с сайта разработчиков, одновременно определив разрядность и необходимый формат пакетов вашей системы. В данный момент возможна установка *.deb* и *.rpm* пакетов (тестировано на Mint 17 и Fedora 23)
## Установка
### Зависимости
Перед установкой, убедитесь, что в вашей системе установлен пакет *zenity* или *dialog* (текствой вариант интерфеса появится в ближайшее время)
### Получение и установка
Получить и установить скрипт можно разными способами, здесь рекомендуем использовать утилиту `curl` или `wget`
#### Используя curl
~~~
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Chocbo/lo_direct_install/master/lo_direct_install.sh)"
~~~
#### Используя wget
~~~
 bash -c "$(wget https://raw.githubusercontent.com/Chocbo/lo_direct_install/master/lo_direct_install.sh -O -)"
~~~
Далее, следуйте подсказкам в появившемся окне установщика.
