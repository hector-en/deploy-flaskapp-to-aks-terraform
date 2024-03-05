document.addEventListener("DOMContentLoaded", function() {
    const paginationLinks = document.querySelectorAll(".pagination-link");
    const orderTable = document.querySelector(".order-table");
    const btnOrders = document.getElementById("btn-orders");
    const btnAddOrder = document.getElementById("btn-add-order");
    const orderListContent = document.getElementById("order-list-content");
    const addOrderContent = document.getElementById("add-order-content");

    // Pagination click event
    paginationLinks.forEach(link => {
        link.addEventListener("click", function(event) {
            event.preventDefault();

            const nextPageURL = this.getAttribute("href");

            // Send AJAX request to fetch next page data
            fetch(nextPageURL)
                .then(response => response.text())
                .then(data => {
                    // Update table and pagination controls
                    const newHTML = new DOMParser().parseFromString(data, "text/html");
                    const newTable = newHTML.querySelector(".order-table");
                    const newPagination = newHTML.querySelector(".pagination");

                    orderTable.innerHTML = newTable.innerHTML;
                    const paginationDiv = document.querySelector(".pagination");
                    paginationDiv.innerHTML = newPagination.innerHTML;

                    // Scroll to the top of the table
                    window.scrollTo({ top: orderTable.offsetTop, behavior: "smooth" });
                })
                .catch(error => {
                    console.error("Error fetching data:", error);
                });
        });
    });

    // Tab buttons click events
    btnOrders.addEventListener("click", function() {
        orderListContent.style.display = "block";
        addOrderContent.style.display = "none";
    });

    btnAddOrder.addEventListener("click", function() {
        orderListContent.style.display = "none";
        addOrderContent.style.display = "block";
    });
});

