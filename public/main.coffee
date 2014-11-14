DEFAULT_SETTINGS =
  sort: "goodreads_rating"
  onlyfiction: "yes"
  onlyavailable: "no"
  query: ""

SORT_FIELDS = [
  ["goodreads_rating", "Goodreads Rating"]
  ["amazon_rating", "Amazon Rating"]
  ["vpl_rating", "VPL Rating"]
  ["title", "Title"]
  ["author", "Author"]
  ["random", "Random"]
]

SEARCHABLE_BOOK_FIELDS = ["title", "author", "description", "tags_string"]

FILTER_OUT_TAGS = ["to-read", "to-read-library", "to-read-short-stories", "currently-reading", "fiction", "non-fiction", "nonfiction", "book-club", "bookclub", "favorites", "favourites", "novels", "novel", "before-goodreads", "to-buy", "finished", "kindle", "read-2006"]

BookApp = React.createFactory React.createClass
  displayName: "BookApp"

  getInitialState: ->
    books: _.values(bookData)
    settings: @currentSettings()

  currentSettings: ->
    hash = getHash()
    out = {}
    for key, val of DEFAULT_SETTINGS
      out[key] = if hash[key]? then hash[key] else val
    out

  componentWillMount: ->
    window.onhashchange = =>
      @setState settings: @currentSettings()

  render: ->
    React.DOM.div className: "app",
      React.DOM.h1 null, "The VanCity Book Club Nook"
      React.DOM.div className: "main",
        Settings(settings: @state.settings)
        BookList(books: @state.books, sort: @state.settings.sort, onlyfiction: @state.settings.onlyfiction, onlyavailable: @state.settings.onlyavailable, query: @state.settings.query)

BookList = React.createFactory React.createClass
  displayName: "BookList"

  getInitialState: ->
    numToShow: 10

  render: ->
    books = @props.books

    # filter
    books = (b for b in books when b.fiction) if @props.onlyfiction is "yes"
    books = (b for b in books when b.available) if @props.onlyavailable is "yes"
    books = (b for b in books when matchesQuery(b, query)) if (query = @props.query) and !_.isEmpty(query)

    # sort
    books = _.sortBy books, (b) =>
      switch @props.sort
        when "goodreads_rating", "amazon_rating", "vpl_rating"
          -b[@props.sort]
        when "random"
          Math.random()
        else
          b[@props.sort]

    # slice
    hasMore = books.length > @state.numToShow
    books = books.slice(0, @state.numToShow) if hasMore

    unless _.isEmpty(books)
      InfiniteScroll hasMore: hasMore, loadMore: @loadMore,
        React.DOM.ul className: "book-list",
          BookListItem(key: book.vpl_id, book: book, showFiction: @props.onlyfiction is "no", showAvailability: @props.onlyavailable is "no") for id, book of books
    else
      React.DOM.ul className: "book-list",
        React.DOM.li className: "no-results", "Sorry, no books match that set of criteria."

  loadMore: ->
    @setState { numToShow: @state.numToShow + 10 }

BookListItem = React.createFactory React.createClass
  displayName: "BookListItem"

  shouldComponentUpdate: (nextProps, nextState) ->
    @props.book isnt nextProps.book or @props.showFiction isnt nextProps.showFiction or @props.showAvailability isnt nextProps.showAvailability

  render: ->
    { vpl_id, title, vpl_url, author, availability, available, availability_url, holds, vpl_rating, isbn, img, goodreads_id, goodreads_url, goodreads_rating, amazon_url, amazon_rating, tags, description, fiction } = @props.book

    React.DOM.li {},
      React.DOM.div className: "cover",
        React.DOM.a href: vpl_url,
          React.DOM.img src: img
      React.DOM.h3 className: "title",
        React.DOM.a href: vpl_url, className: "vpl-link", title
      React.DOM.h4 className: "author", author
      React.DOM.div className: "description", description or " "
      React.DOM.ul className: "categories",
        for c in tags
          React.DOM.li key: c, c
      React.DOM.div className: "metadata",
        if @props.showAvailability
          React.DOM.div className: "availability",
            React.DOM.span className: "yesno #{if available then 'yes' else 'no'}", "Available:"
            React.DOM.span className: "holds", "(#{holds.replace(/Holds: (\d+)/, '$1 holds')})" if holds
        if @props.showFiction
          React.DOM.div className: "fiction yesno #{if fiction then 'yes' else 'no'}", "Fiction:"
        React.DOM.div className: "goodreads-rating",
          React.DOM.a href: goodreads_url, @renderRating(goodreads_rating, 5)
        React.DOM.div className: "amazon-rating",
          React.DOM.a href: amazon_url, @renderRating(amazon_rating, 1)
        React.DOM.div className: "vpl-rating",
          React.DOM.a href: vpl_url, @renderRating(vpl_rating, 100)

  renderRating: (val, outOf) ->
    if val?
      pct = Math.round(val / outOf * 100)
      React.DOM.span className: "rating",
        React.DOM.span className: "stars", style: { width: "#{pct}%" }
    else
      "-"

Settings = React.createFactory React.createClass
  displayName: "Settings"

  render: ->
    React.DOM.form className: "settings",
      Dropdown(property: "sort", id: "sort-setting", value: @props.settings.sort, label: "Sort by:", options: SORT_FIELDS)
      Checkbox(property: "onlyfiction", id: "only-fiction-setting", value: @props.settings.onlyfiction, label: "Fiction only?")
      Checkbox(property: "onlyavailable", id: "only-available-setting", value: @props.settings.onlyavailable, label: "Available sets only?")
      TextField(property: "query", id: "query-setting", value: @props.settings.query, label: "Search:")

Dropdown = React.createFactory React.createClass
  displayName: "Dropdown"

  render: ->
    React.DOM.fieldset null,
      React.DOM.label htmlFor: @props.id, @props.label
      React.DOM.select id: @props.id, value: @props.value, onChange: @handleChange,
        for [key, name] in SORT_FIELDS
          React.DOM.option key: key, value: key, name

  handleChange: (ev) ->
    updateHash @props.property, ev.target.value

Checkbox = React.createFactory React.createClass
  displayName: "Checkbox"

  render: ->
    React.DOM.fieldset null,
      React.DOM.label htmlFor: @props.id, @props.label
      React.DOM.input id: @props.id, type: "checkbox", name: @props.property, value: "yes", checked: @props.value is "yes", onChange: @handleChange

  handleChange: (ev) ->
    updateHash @props.property, if ev.target.checked then "yes" else "no"

TextField = React.createFactory React.createClass
  displayName: "TextField"

  render: ->
    React.DOM.fieldset null,
      React.DOM.label htmlFor: @props.id, @props.label
      React.DOM.input id: @props.id, type: "text", name: @props.property, value: @props.value, onChange: @handleChange

  handleChange: (ev) ->
    updateHash @props.property, ev.target.value

################################################################################
# Adapted from https://github.com/guillaumervls/react-infinite-scroll
# Copyright (c) 2013 guillaumervls, MIT License
#
InfiniteScroll = React.createFactory React.createClass
  getDefaultProps: ->
    hasMore: false
    loadMore: ->
    threshold: 250

  componentDidMount: ->
    @attachScrollListener()

  componentDidUpdate: ->
    @attachScrollListener()

  componentWillUnmount: ->
    @detachScrollListener()

  render: ->
    React.DOM.div null, @props.children

  scrollListener: ->
    el = @getDOMNode()
    scrollTop = (if window.pageYOffset? then window.pageYOffset else (document.documentElement or document.body.parentNode or document.body).scrollTop)
    if topPosition(el) + el.offsetHeight - scrollTop - window.innerHeight < Number(@props.threshold)
      @detachScrollListener()
      @props.loadMore()

  attachScrollListener: ->
    return unless @props.hasMore
    window.addEventListener "scroll", @scrollListener
    window.addEventListener "resize", @scrollListener
    @scrollListener()

  detachScrollListener: ->
    window.removeEventListener "scroll", @scrollListener
    window.removeEventListener "resize", @scrollListener

topPosition = (el) ->
  return 0 unless el
  el.offsetTop + topPosition(el.offsetParent)
#
################################################################################

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
  window.location.hash = "#" + ("#{k}=#{v}" for k, v of h when v and !_.isEmpty(v)).join("&")

cleanBookData = ->
  # will be present in window.bookData, defined in the auto-generated books.js file
  for id, book of bookData
    book.vpl_url = "http://vpl.bibliocommons.com#{book.vpl_url}"
    book.goodreads_url = "https://www.goodreads.com/book/show/#{book.goodreads_id}"
    book.available = book.availability is "Available"
    book.description = book.description.replace(/&?nbsp;?/g, " ") if book.description

    if categories = book.goodreads_categories
      book.tags = (c for c in categories when !(c in FILTER_OUT_TAGS))
      book.fiction = if "non-fiction" in categories or "nonfiction" in categories
        false
      else if "fiction" in categories or "mystery" in categories or "fantasy" in categories
        true
      else if _.find(categories, (c) -> c.indexOf("-fiction") isnt -1)
        true
      else
        false
    else
      book.tags = []
      book.fiction = false

    # stringify tags for text search
    book.tags_string = book.tags.join(" ")

matchesQuery = (book, query) ->
  re = new RegExp(query, "i")
  for f in SEARCHABLE_BOOK_FIELDS
    return true if book[f] and re.test(book[f])
  false

boot = ->
  cleanBookData()
  React.render(BookApp(), document.getElementsByTagName("body")[0])

boot()
