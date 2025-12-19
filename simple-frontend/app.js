(() => {
  const baseUrlInput = document.getElementById('baseUrl');
  const authTokenInput = document.getElementById('authToken');
  const clearTokenBtn = document.getElementById('clearTokenBtn');
  const responseBox = document.getElementById('responseBox');
  const currentUserInfo = document.getElementById('currentUserInfo');
  const wfUserId = document.getElementById('wfUserId');
  const wfEventId = document.getElementById('wfEventId');
  const wfReservationId = document.getElementById('wfReservationId');
  const wfIntentId = document.getElementById('wfIntentId');
  const wfPaymentId = document.getElementById('wfPaymentId');

  let currentUser = null;

  function setWorkflowValue(el, value) {
    if (!el || value === undefined || value === null || value === '') return;
    el.textContent = String(value);
  }

  function getBaseUrl() {
    return baseUrlInput.value.replace(/\/$/, '');
  }

  function setToken(token) {
    if (!token) return;
    authTokenInput.value = token;
  }

  function setCurrentUser(user) {
    currentUser = user;
    if (user) {
      const id = user.userId || user.id;
      currentUserInfo.textContent = `Logged in as ${user.email} (ID: ${id || 'n/a'})`;
      setWorkflowValue(wfUserId, id);
    } else {
      currentUserInfo.textContent = '';
      setWorkflowValue(wfUserId, '-');
    }
  }

  async function apiRequest(method, path, body, extraOptions = {}) {
    const url = getBaseUrl() + path;
    const headers = Object.assign({ 'Content-Type': 'application/json' }, extraOptions.headers || {});
    const token = authTokenInput.value.trim();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const options = {
      method,
      headers,
    };

    if (body && (method === 'POST' || method === 'PUT' || method === 'PATCH')) {
      options.body = JSON.stringify(body);
    }

    const res = await fetch(url, options);
    let data;
    const text = await res.text();
    try {
      data = text ? JSON.parse(text) : null;
    } catch (e) {
      data = text;
    }
    const payload = { status: res.status, ok: res.ok, headers: Object.fromEntries(res.headers.entries()), body: data };
    responseBox.textContent = JSON.stringify(payload, null, 2);
    if (!res.ok) {
      throw new Error(`Request failed with status ${res.status}`);
    }
    return data;
  }

  // Auth
  document.getElementById('registerForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const form = e.target;
    const body = {
      firstName: form.firstName.value.trim(),
      lastName: form.lastName.value.trim(),
      email: form.email.value.trim(),
      password: form.password.value,
    };
    try {
      const data = await apiRequest('POST', '/auth/register', body);
      if (data && data.token) {
        setToken(data.token);
        setCurrentUser(data);
      }
    } catch (err) {
      console.error(err);
    }
  });

  document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const form = e.target;
    const body = {
      email: form.email.value.trim(),
      password: form.password.value,
    };
    try {
      const data = await apiRequest('POST', '/auth/login', body);
      if (data && data.token) {
        setToken(data.token);
        setCurrentUser(data);
      }
    } catch (err) {
      console.error(err);
    }
  });

  document.getElementById('meBtn').addEventListener('click', async () => {
    try {
      const data = await apiRequest('GET', '/users/me');
      setCurrentUser(data);
    } catch (err) {
      console.error(err);
    }
  });

  clearTokenBtn.addEventListener('click', () => {
    authTokenInput.value = '';
    setCurrentUser(null);
  });

  // Events
  document.getElementById('listEventsBtn').addEventListener('click', async () => {
    try {
      const data = await apiRequest('GET', '/events?page=0&size=20');
      if (data && Array.isArray(data.content) && data.content.length > 0) {
        setWorkflowValue(wfEventId, data.content[0].id);
      }
    } catch (err) {
      console.error(err);
    }
  });

  document.getElementById('createEventForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const form = e.target;
    const organizerId = form.organizerId.value || (currentUser && (currentUser.userId || currentUser.id));
    const body = {
      title: form.title.value.trim(),
      description: form.description.value.trim(),
      eventType: form.eventType.value.trim(),
      venue: form.venue.value.trim(),
      address: form.address ? form.address.value.trim() : undefined,
      city: form.city.value.trim() || undefined,
      country: form.country.value.trim() || undefined,
      capacity: Number(form.capacity.value || 0),
      price: Number(form.price.value || 0),
      startDate: form.startDate.value,
      endDate: form.endDate.value || undefined,
      organizerId: organizerId ? Number(organizerId) : 1,
    };
    try {
      const data = await apiRequest('POST', '/events', body);
      if (data && (data.id !== undefined || data.eventId !== undefined)) {
        setWorkflowValue(wfEventId, data.id ?? data.eventId);
      }
    } catch (err) {
      console.error(err);
    }
  });

  // Reservations
  document.getElementById('createReservationForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const form = e.target;
    const rawUserId = form.userId.value || (currentUser && (currentUser.userId || currentUser.id));
    if (!rawUserId) {
      alert('User ID is required (login or fill the field).');
      return;
    }
    const rawEventId = form.eventId.value || (wfEventId && wfEventId.textContent !== '-' ? wfEventId.textContent : '');
    if (!rawEventId) {
      alert('Event ID is required (create event first or fill the field).');
      return;
    }
    const body = {
      userId: Number(rawUserId),
      eventId: Number(rawEventId),
      quantity: Number(form.quantity.value || 1),
      idempotencyKey: `simple-ui-${Date.now()}-${Math.random().toString(36).slice(2)}`,
    };
    try {
      const data = await apiRequest('POST', '/reservations', body);
      if (data && (data.reservationId || data.id)) {
        setWorkflowValue(wfReservationId, data.reservationId || data.id);
      }
    } catch (err) {
      console.error(err);
    }
  });

  document.getElementById('userReservationsForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const form = e.target;
    const userId = form.userId.value || (currentUser && (currentUser.userId || currentUser.id));
    if (!userId) return alert('User ID is required (login or fill the field).');
    try {
      await apiRequest('GET', `/reservations/user/${Number(userId)}`);
    } catch (err) {
      console.error(err);
    }
  });

  document.getElementById('confirmReservationForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const form = e.target;
    let id = form.reservationId.value.trim();
    if (!id && wfReservationId && wfReservationId.textContent !== '-') {
      id = wfReservationId.textContent.trim();
    }
    if (!id) {
      alert('Reservation ID is required (create reservation first or fill the field).');
      return;
    }
    try {
      await apiRequest('POST', `/reservations/${encodeURIComponent(id)}/confirm`);
    } catch (err) {
      console.error(err);
    }
  });

  document.getElementById('cancelReservationForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const form = e.target;
    let id = form.reservationId.value.trim();
    if (!id && wfReservationId && wfReservationId.textContent !== '-') {
      id = wfReservationId.textContent.trim();
    }
    if (!id) {
      alert('Reservation ID is required (create reservation first or fill the field).');
      return;
    }
    try {
      await apiRequest('POST', `/reservations/${encodeURIComponent(id)}/cancel`);
    } catch (err) {
      console.error(err);
    }
  });

  // Payments
  document.getElementById('createPaymentIntentForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const form = e.target;
    const rawUserId = form.userId.value || (currentUser && (currentUser.userId || currentUser.id));
    if (!rawUserId) {
      alert('User ID is required (login or fill the field).');
      return;
    }
    let reservationId = form.reservationId.value.trim();
    if (!reservationId && wfReservationId && wfReservationId.textContent !== '-') {
      reservationId = wfReservationId.textContent.trim();
    }
    if (!reservationId) {
      alert('Reservation ID is required (create reservation first or fill field).');
      return;
    }
    const body = {
      reservationId,
      userId: Number(rawUserId),
      amount: Number(form.amount.value),
      currency: form.currency.value.trim() || undefined,
      paymentMethod: form.paymentMethod.value.trim() || undefined,
      description: form.description.value.trim() || undefined,
      idempotencyKey: `simple-ui-${Date.now()}-${Math.random().toString(36).slice(2)}`,
    };
    try {
      const data = await apiRequest('POST', '/payments/intents', body);
      if (data && (data.intentId || data.id)) {
        setWorkflowValue(wfIntentId, data.intentId || data.id);
      }
    } catch (err) {
      console.error(err);
    }
  });

  document.getElementById('capturePaymentForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const form = e.target;
    let intentId = form.intentId.value.trim();
    if (!intentId && wfIntentId && wfIntentId.textContent !== '-') {
      intentId = wfIntentId.textContent.trim();
    }
    if (!intentId) {
      alert('Intent ID is required (create payment intent first or fill field).');
      return;
    }
    const key = form.idempotencyKey.value.trim();
    const query = key ? `?idempotencyKey=${encodeURIComponent(key)}` : '';
    try {
      const data = await apiRequest('POST', `/payments/intents/${encodeURIComponent(intentId)}/capture${query}`);
      if (data && (data.paymentId || data.id)) {
        setWorkflowValue(wfPaymentId, data.paymentId || data.id);
      }
    } catch (err) {
      console.error(err);
    }
  });

  document.getElementById('getIntentForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const form = e.target;
    const intentId = form.intentId.value.trim();
    if (!intentId) return;
    try {
      await apiRequest('GET', `/payments/intents/${encodeURIComponent(intentId)}`);
    } catch (err) {
      console.error(err);
    }
  });

  document.getElementById('userPaymentsForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const form = e.target;
    const userId = form.userId.value || (currentUser && (currentUser.userId || currentUser.id));
    if (!userId) return alert('User ID is required (login or fill the field).');
    try {
      await apiRequest('GET', `/payments/user/${Number(userId)}`);
    } catch (err) {
      console.error(err);
    }
  });

  document.getElementById('userPaymentIntentsForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const form = e.target;
    const userId = form.userId.value || (currentUser && (currentUser.userId || currentUser.id));
    if (!userId) return alert('User ID is required (login or fill the field).');
    try {
      await apiRequest('GET', `/payments/intents/user/${Number(userId)}`);
    } catch (err) {
      console.error(err);
    }
  });

  // Generic request
  document.getElementById('genericRequestForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    const form = e.target;
    const method = form.method.value.toUpperCase();
    let path = form.path.value.trim();
    if (!path.startsWith('/')) path = '/' + path;
    let body = undefined;
    if (form.body.value.trim()) {
      try {
        body = JSON.parse(form.body.value);
      } catch (err) {
        alert('Body is not valid JSON.');
        return;
      }
    }
    try {
      await apiRequest(method, path, body);
    } catch (err) {
      console.error(err);
    }
  });
})();
