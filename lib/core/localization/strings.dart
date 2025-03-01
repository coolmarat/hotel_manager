class Strings {
  static const appTitle = 'Управление отелем';
  
  // Общие строки
  static const cancel = 'Отмена';
  static const save = 'Сохранить';
  static const delete = 'Удалить';
  static const edit = 'Редактировать';
  static const add = 'Добавить';
  static const error = 'Ошибка';
  
  // Статусы комнат
  static const roomStatuses = {
    'available': 'Свободна',
    'occupied': 'Занята',
    'cleaning': 'Уборка',
    'maintenance': 'Обслуживание',
  };
  
  // Экран комнат
  static const rooms = 'Комнаты';
  static const allRooms = 'Все комнаты';
  static const noRooms = 'Нет добавленных комнат';
  static const addRoom = 'Добавить комнату';
  static const editRoom = 'Редактировать комнату';
  static const deleteRoomConfirm = 'Вы уверены, что хотите удалить эту комнату? Это действие нельзя отменить.';
  static const roomName = 'Название комнаты';
  static const roomNameHint = 'Введите название или номер комнаты';
  static const roomType = 'Тип комнаты';
  static const roomTypeHint = 'например, Стандарт, Люкс, Апартаменты';
  static const capacity = 'Вместимость';
  static const capacityHint = 'Максимальное количество гостей';
  static const basePrice = 'Базовая цена';
  static const basePriceHint = 'Цена за ночь';
  static const description = 'Описание';
  static const descriptionHint = 'Введите описание комнаты';
  static const status = 'Статус';
  static const type = 'Тип';
  static const guests = 'гостей';
  
  // Экран бронирований
  static const bookings = 'Бронирования';
  static const noBookings = 'Нет бронирований';
  static const addBooking = 'Добавить бронирование';
  static const editBooking = 'Редактировать бронирование';
  static const deleteBookingConfirm = 'Вы уверены, что хотите удалить это бронирование? Это действие нельзя отменить.';
  static const checkIn = 'Заезд';
  static const checkOut = 'Выезд';
  static const guestName = 'Имя гостя';
  static const guestNameHint = 'Введите имя гостя';
  static const guestPhone = 'Телефон гостя';
  static const guestPhoneHint = 'Введите телефон гостя';
  static const totalPrice = 'Общая стоимость';
  static const amountPaid = 'Оплачено';
  static const notes = 'Заметки';
  static const notesHint = 'Дополнительная информация';
  static const calendar = 'Календарь';
  static const callGuest = 'Позвонить клиенту';
  static const addPayment = 'Указать оплату';
  static const enterPaymentAmount = 'Введите сумму оплаты';
  static const payment = 'Оплата';
  static const paymentAmount = 'Сумма оплаты';
  static const paymentAmountHint = 'Введите сумму оплаты';
  static const remainingAmount = 'Осталось оплатить';
  
  // Статусы оплаты
  static const paymentStatuses = {
    'unpaid': 'Не оплачено',
    'partiallyPaid': 'Частично оплачено',
    'paid': 'Оплачено',
  };
  
  // Экран отчетов
  static const reports = 'Отчеты';
  static const occupancyRate = 'Загрузка отеля';
  static const revenue = 'Выручка';
  static const daily = 'За день';
  static const weekly = 'За неделю';
  static const monthly = 'За месяц';
  static const bookingsOverview = 'Обзор бронирований';
  static const totalBookings = 'Всего бронирований';
  static const checkInsToday = 'Заездов сегодня';
  static const checkOutsToday = 'Выездов сегодня';
  static const roomsOccupied = 'комнат занято';
  static const selectedPeriod = 'Выбранный период';
  static const changePeriod = 'Изменить';
  static const revenueForPeriod = 'Выручка за период';
  static const periodStatistics = 'Статистика за выбранный период';
  static const totalBookingsInPeriod = 'Всего бронирований:';
  static const checkInsInPeriod = 'Заездов:';
  static const checkOutsInPeriod = 'Выездов:';
  static const totalRevenueInPeriod = 'Общая выручка:';
  
  // Валидация
  static const required = 'Обязательное поле';
  static const invalidCapacity = 'Введите корректное количество гостей';
  static const invalidPrice = 'Введите корректную цену';
  static const invalidPhone = 'Введите корректный номер телефона';
}
