BookApp = React.createClass
  displayName: "BookApp"

  getInitialState: ->
    books: _.values(bookData)
    settings: @currentSettings()

  currentSettings: ->
    hash = getHash()
    {
      sort: hash.sort or "title"
    }

  componentWillMount: ->
    window.onhashchange = =>
      @setState settings: @currentSettings()

  render: ->
    React.DOM.div className: "app",
      Settings(settings: @state.settings)
      BookList(books: @state.books, sort: @state.settings.sort)

BookList = React.createClass
  displayName: "BookList"

  render: ->
    sortedBooks = _.sortBy @props.books, (b) =>
      if @props.sort.indexOf("rating") isnt -1
        -b[@props.sort]
      else
        b[@props.sort]
    React.DOM.ul className: "book-list",
      BookListItem(key: book.vpl_id, book: book) for id, book of sortedBooks

BookListItem = React.createClass
  displayName: "BookListItem"

  shouldComponentUpdate: (nextProps, nextState) ->
    @props.book isnt nextProps.book

  render: ->
    { vpl_id, title, vpl_url, author, availability, available, availability_url, holds, vpl_rating, isbn, img, goodreads_id, goodreads_url, goodreads_rating, amazon_url, amazon_rating, goodreads_categories, description, fiction } = @props.book

    React.DOM.li className: "book-item",
      React.DOM.div className: "cover",
        React.DOM.a href: vpl_url,
          React.DOM.img src: img
      React.DOM.h3 className: "title",
        React.DOM.a href: vpl_url, className: "vpl-link", title
      React.DOM.h4 className: "author", author
      React.DOM.div className: "description", description or " "
      React.DOM.ul className: "categories",
        if goodreads_categories
          for c in goodreads_categories when !(c in ["to-read", "currently-reading", "fiction", "non-fiction", "nonfiction", "book-club", "favorites", "novels", "novel", "before-goodreads", "to-buy", "finished"])
            React.DOM.li key: c, c
      React.DOM.div className: "metadata",
        React.DOM.div className: "availability",
          React.DOM.span className: "yesno #{if available then 'yes' else 'no'}", "Available:"
          React.DOM.span className: "holds", "(#{holds.replace(/Holds: (\d+)/, '$1 holds')})" if holds
        React.DOM.div className: "fiction yesno #{if fiction then 'yes' else 'no'}", "Fiction:"
        # React.DOM.div className: "vpl-rating",
        #   React.DOM.a href: vpl_url, @renderRating(vpl_rating, 100)
        React.DOM.div className: "amazon-rating",
          React.DOM.a href: amazon_url, @renderRating(amazon_rating, 1)
        React.DOM.div className: "goodreads-rating",
          React.DOM.a href: goodreads_url, @renderRating(goodreads_rating, 5)

  renderRating: (val, outOf) ->
    if val?
      stars = Math.round(val / outOf * 6) + 1
      React.DOM.span className: "rating",
        React.DOM.span className: "stars-#{stars}"
    else
      "-"

Settings = React.createClass
  displayName: "Settings"

  render: ->
    React.DOM.div className: "settings",
      SortFieldChooser(field: @props.settings.sort)

SortFieldChooser = React.createClass
  displayName: "SortFieldChooser"

  render: ->
    React.DOM.fieldset null,
      React.DOM.label htmlFor: "sort-field-chooser", "Sort by:"
      React.DOM.select id: "sort-field-chooser", className: "sortFieldChooser", value: @props.field, onChange: @handleChange,
        for [key, name] in SORT_FIELDS
          React.DOM.option key: key, value: key, name

  handleChange: (ev) ->
    updateHash "sort", ev.target.value

SORT_FIELDS = [
  ["title", "Title"]
  ["author", "Author"]
  ["amazon_rating", "Amazon Rating"]
  ["goodreads_rating", "Goodreads Rating"]
]

getHash = ->
  if (h = window.location.hash) and !_.isEmpty(h)
    out = {}
    for s in h[1..].split("&")
      [k, v] = s.split("=")
      out[k] = v
    out
  else
    {}

updateHash = (key, val) ->
  h = getHash()
  h[key] = val
  window.location.hash = "#" + ("#{k}=#{v}" for k, v of h).join("&")

boot = ->
  for id, book of bookData
    book.vpl_url = "http://vpl.bibliocommons.com#{book.vpl_url}"
    book.goodreads_url = "https://www.goodreads.com/book/show/#{book.goodreads_id}"
    book.available = book.availability is "Available"

    if categories = book.goodreads_categories
      book.fiction = if "non-fiction" in categories or "nonfiction" in categories
        false
      else if "fiction" in categories or "mystery" in categories or "fantasy" in categories
        true
      else if _.find(categories, (c) -> c.indexOf("-fiction") isnt -1)
        true
      else
        false

  React.renderComponent(BookApp(), document.getElementsByTagName("body")[0])

boot()
