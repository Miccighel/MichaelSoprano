$(document).ready(() => {
    $("#publications-table").DataTable({
        "paging": false,
        "info": false,
        "columnDefs": [{
            "targets": 5,
            "orderable": false
        }],
    });
});