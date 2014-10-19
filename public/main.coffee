BookList = React.createClass
  displayName: "BookList"

  render: ->
    React.DOM.ul className: "book-list",
      BookListItem(key: id, book: book) for id, book of @props.books

BookListItem = React.createClass
  displayName: "BookListItem"

  render: ->
    { vpl_id, title, vpl_url, author, availability, availability_url, holds, vpl_rating, isbn, img, goodreads_id, goodreads_url, goodreads_rating, amazon_url, amazon_rating, goodreads_categories, description, fiction } = @props.book

    React.DOM.li className: "book-item",
      React.DOM.div className: "cover",
        React.DOM.a href: vpl_url,
          React.DOM.img src: img
      React.DOM.h3 className: "title",
        React.DOM.a href: vpl_url, className: "vpl-link", title
      React.DOM.h4 className: "author", author
      React.DOM.div className: "description", description or " "
      React.DOM.div className: "availability",
        "Available: #{availability}"
        React.DOM.span className: "holds", holds if holds
      React.DOM.div className: "fiction", "Fiction: #{if fiction then "Yes" else "No"}"
      React.DOM.div className: "vpl-rating",
        React.DOM.a href: vpl_url, vpl_rating
      React.DOM.div className: "amazon-rating",
        React.DOM.a href: amazon_url, amazon_rating
      React.DOM.div className: "goodreads-rating",
        React.DOM.a href: goodreads_url, goodreads_rating

$(document).ready ->
  for id, book of bookData
    book.vpl_url = "http://vpl.bibliocommons.com#{book.vpl_url}"
    book.goodreads_url = "https://www.goodreads.com/book/show/#{book.goodreads_id}"

    if categories = book.goodreads_categories
      book.fiction = if "non-fiction" in categories or "nonfiction" in categories
        false
      else if "fiction" in categories or "mystery" in categories or "fantasy" in categories
        true
      else if _.find(categories, (c) -> c.indexOf("-fiction") isnt -1)
        true
      else
        false

  React.renderComponent(BookList(books: _.values(bookData)), $("#bookList")[0])
