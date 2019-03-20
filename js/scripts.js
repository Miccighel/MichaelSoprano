$(document).ready(() => {

    let contactMailFormFirst = $("#contact-mail-form-first");

    let publicationsTable = $("#publications-table");

    let contactMailButtonFirst = $("#contact-mail-button-first");
    let contactMailResultFirst = $("#contact-mail-result-first");

    let nameFieldFirst = $("#name-field-first");
    let emailFieldFirst = $("#email-field-first");
    let subjectFieldFirst = $("#subject-field-first");
    let messageFieldFirst = $("#message-field-first");

    let contactMailFormSecond = $("#contact-mail-form-second");

    let contactMailButtonSecond = $("#contact-mail-button-second");
    let contactMailResultSecond = $("#contact-mail-result-second");

    let nameFieldSecond = $("#name-field-second");
    let emailFieldSecond = $("#email-field-second");
    let subjectFieldSecond = $("#subject-field-second");
    let messageFieldSecond = $("#message-field-second");

    let reloadIcons = $(".reload-icon");

    reloadIcons.hide();
    contactMailFormFirst.submit(event => event.preventDefault());
    contactMailResultFirst.hide();
    contactMailFormSecond.submit(event => event.preventDefault());
    contactMailResultSecond.hide();

    // PUBLICATIONS TABLE

    publicationsTable.DataTable({
        "paging": false,
        "info": false,
        "responsive": true,
        "columnDefs": [{
            "targets": 5,
            "orderable": false
        }],
    });

    // CONTACT MAIL

    contactMailButtonFirst.on("click", () => {
        let validationInstance = contactMailFormFirst.parsley();
        validationInstance.validate();
        if (validationInstance.isValid()) {
            reloadIcons.toggle();
            let email = emailFieldFirst.val();
            let subject = subjectFieldFirst.val();
            let body = `
            Name: ${nameFieldFirst.val()}
            <br /><br />
            ---------- 
            <br /><br />
            Contact Mail: ${email}
            <br /><br />
            ---------- 
            <br /><br /> 
            Message: ${messageFieldFirst.val()} 
            <br /><br /> 
            ---------- 
            <br /><br /> 
            Have a nice day! 
           `;
            Email.send({
                SecureToken: "3c5978bf-7dc5-438d-8ea4-732cca054b0f",
                To: "michael.soprano@outlook.com",
                From: `MichaelSoprano.com <${email}>`,
                Subject: subject,
                Body: body
            }).then(
                message => {
                    reloadIcons.toggle();
                    contactMailButtonFirst.prop("disabled", true);
                    contactMailButtonFirst.removeClass("btn-primary");
                    contactMailButtonFirst.addClass("btn-border");
                    contactMailResultFirst.addClass("background-green");
                    contactMailResultFirst.text(`Email successfully sent: ${message}`);
                    contactMailResultFirst.show();
                    contactMailButtonSecond.prop("disabled", true);
                    contactMailButtonSecond.removeClass("btn-primary");
                    contactMailButtonSecond.addClass("btn-border");
                    contactMailResultSecond.addClass("background-green");
                    contactMailResultSecond.text(`Email successfully sent: ${message}`);
                    contactMailResultSecond.show();
                }, reason => {
                    reloadIcons.toggle();
                    contactMailButtonFirst.prop("disabled", true);
                    contactMailButtonFirst.removeClass("btn-primary");
                    contactMailButtonFirst.addClass("btn-border");
                    contactMailResultFirst.addClass("background-red");
                    contactMailResultFirst.text(`Email could not be sent: ${reason}`);
                    contactMailResultFirst.show();
                    contactMailButtonSecond.prop("disabled", true);
                    contactMailButtonSecond.removeClass("btn-primary");
                    contactMailButtonSecond.addClass("btn-border");
                    contactMailResultSecond.addClass("background-red");
                    contactMailResultSecond.text(`Email could not be sent: ${reason}`);
                    contactMailResultSecond.show();
                });
        }
    });

    contactMailButtonSecond.on("click", () => {
        let validationInstance = contactMailFormSecond.parsley();
        validationInstance.validate();
        if (validationInstance.isValid()) {
            reloadIcons.toggle();
            let email = emailFieldSecond.val();
            let subject = subjectFieldSecond.val();
            let body = `
            Name: ${nameFieldSecond.val()}
            <br /><br />
            ---------- 
            <br /><br />
            Contact Mail: ${email}
            <br /><br />
            ---------- 
            <br /><br /> 
            Message: ${messageFieldSecond.val()} 
            <br /><br /> 
            ---------- 
            <br /><br /> 
            Have a nice day! 
           `;
            Email.send({
                SecureToken: "3c5978bf-7dc5-438d-8ea4-732cca054b0f",
                To: "michael.soprano@outlook.com",
                From: `MichaelSoprano.com <${email}>`,
                Subject: subject,
                Body: body
            }).then(
                message => {
                    reloadIcons.toggle();
                    contactMailButtonFirst.prop("disabled", true);
                    contactMailButtonFirst.removeClass("btn-primary");
                    contactMailButtonFirst.addClass("btn-border");
                    contactMailResultFirst.addClass("background-green");
                    contactMailResultFirst.text(`Email successfully sent: ${message}`);
                    contactMailResultFirst.show();
                    contactMailButtonSecond.prop("disabled", true);
                    contactMailButtonSecond.removeClass("btn-primary");
                    contactMailButtonSecond.addClass("btn-border");
                    contactMailResultSecond.addClass("background-green");
                    contactMailResultSecond.text(`Email successfully sent: ${message}`);
                    contactMailResultSecond.show();
                }, reason => {
                    reloadIcons.toggle();
                    contactMailButtonFirst.prop("disabled", true);
                    contactMailButtonFirst.removeClass("btn-primary");
                    contactMailButtonFirst.addClass("btn-border");
                    contactMailResultFirst.addClass("background-red");
                    contactMailResultFirst.text(`Email could not be sent: ${reason}`);
                    contactMailResultFirst.show();
                    contactMailButtonSecond.prop("disabled", true);
                    contactMailButtonSecond.removeClass("btn-primary");
                    contactMailButtonSecond.addClass("btn-border");
                    contactMailResultSecond.addClass("background-red");
                    contactMailResultSecond.text(`Email could not be sent: ${reason}`);
                    contactMailResultSecond.show();
                });
        }
    });

});