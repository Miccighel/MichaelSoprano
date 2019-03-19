$(document).ready(() => {
    $("#publications-table").DataTable({
        "paging": false,
        "info": false,
        "responsive": true,
        "columnDefs": [{
            "targets": 5,
            "orderable": false
        }],
    });
});