(() => {
  const form = document.querySelector("[data-contact-form]");
  if (!form) return;

  // The in-app/local preview may not be allowed to make cross-origin requests.
  // Keep the native HTML POST there; production still gets the inline AJAX UX.
  if (["localhost", "127.0.0.1", "::1"].includes(window.location.hostname)) return;

  const submit = form.querySelector("[data-contact-submit]");
  const status = form.querySelector("[data-contact-form-status]");
  const honeypot = form.elements.namedItem("_gotcha");
  if (!submit || !status) return;

  const setStatus = (message, state = "") => {
    status.hidden = false;
    status.dataset.state = state;
    status.textContent = message;
  };

  const responseError = (response, payload) => {
    const errors = Array.isArray(payload?.errors)
      ? payload.errors.map((error) => error?.message).filter(Boolean).join(" ")
      : "";
    if (errors) return errors;
    if (response.status === 403) return "The contact form is not authorized for this site. Please use the email address above.";
    if (response.status === 404) return "The contact form endpoint was not found. Please use the email address above.";
    if (response.status === 429) return "Too many submissions in a short time. Please wait a moment and try again.";
    return `The message could not be sent (error ${response.status}). Please use the email address above.`;
  };

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    if (honeypot && honeypot.value) {
      form.reset();
      setStatus("Message sent. Thank you.", "success");
      return;
    }

    submit.disabled = true;
    submit.setAttribute("aria-busy", "true");

    try {
      const response = await fetch(form.action, {
        method: "POST",
        body: new FormData(form),
        headers: { Accept: "application/json" },
      });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(responseError(response, payload));

      form.reset();
      setStatus("Message sent. Thank you; I will get back to you soon.", "success");
    } catch (error) {
      const networkError = error?.name === "TypeError";
      setStatus(
        networkError
          ? "The contact service could not be reached from this page. Please use the email address above."
          : error.message,
        "error",
      );
    } finally {
      submit.disabled = false;
      submit.removeAttribute("aria-busy");
    }
  });
})();
