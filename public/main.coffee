DEFAULT_SETTINGS =
  sort: "goodreads_rating"
  onlyfiction: "yes"
  onlyavailable: "no"

SORT_FIELDS = [
  ["goodreads_rating", "Goodreads Rating"]
  ["amazon_rating", "Amazon Rating"]
  ["title", "Title"]
  ["author", "Author"]
]

BookApp = React.createClass
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
      React.DOM.h1 null, "VPL Book Club Sets"
      Settings(settings: @state.settings)
      BookList(books: @state.books, sort: @state.settings.sort, onlyfiction: @state.settings.onlyfiction, onlyavailable: @state.settings.onlyavailable)

BookList = React.createClass
  displayName: "BookList"

  getInitialState: ->
    numToShow: 10

  render: ->
    books = @props.books

    # filter
    books = (b for b in books when b.fiction) if @props.onlyfiction is "yes"
    books = (b for b in books when b.available) if @props.onlyavailable is "yes"

    # sort
    books = _.sortBy books, (b) =>
      if @props.sort.indexOf("rating") isnt -1
        -b[@props.sort]
      else
        b[@props.sort]

    # slice
    hasMore = books.length > @state.numToShow
    books = books.slice(0, @state.numToShow) if hasMore

    InfiniteScroll hasMore: hasMore, loadMore: @loadMore,
      React.DOM.ul className: "book-list",
        BookListItem(key: book.vpl_id, book: book, showFiction: @props.onlyfiction is "no", showAvailability: @props.onlyavailable is "no") for id, book of books

  loadMore: ->
    @setState { numToShow: @state.numToShow + 10 }

BookListItem = React.createClass
  displayName: "BookListItem"

  shouldComponentUpdate: (nextProps, nextState) ->
    @props.book isnt nextProps.book or @props.showFiction isnt nextProps.showFiction or @props.showAvailability isnt nextProps.showAvailability

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
          for c in goodreads_categories when !(c in ["to-read", "currently-reading", "fiction", "non-fiction", "nonfiction", "book-club", "bookclub", "favorites", "favourites", "novels", "novel", "before-goodreads", "to-buy", "finished", "kindle"])
            React.DOM.li key: c, c
      React.DOM.div className: "metadata",
        if @props.showAvailability
          React.DOM.div className: "availability",
            React.DOM.span className: "yesno #{if available then 'yes' else 'no'}", "Available:"
            React.DOM.span className: "holds", "(#{holds.replace(/Holds: (\d+)/, '$1 holds')})" if holds
        if @props.showFiction
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
    React.DOM.form className: "settings",
      Dropdown(key: "sort", id: "sort-setting", value: @props.settings.sort, label: "Sort by:", options: SORT_FIELDS)
      Checkbox(key: "onlyfiction", id: "only-fiction-setting", value: @props.settings.onlyfiction, label: "Fiction only?")
      Checkbox(key: "onlyavailable", id: "only-available-setting", value: @props.settings.onlyavailable, label: "Available sets only?")

Dropdown = React.createClass
  displayName: "Dropdown"

  render: ->
    React.DOM.fieldset null,
      React.DOM.label htmlFor: @props.id, @props.label
      React.DOM.select id: @props.id, value: @props.value, onChange: @handleChange,
        for [key, name] in SORT_FIELDS
          React.DOM.option key: key, value: key, name

  handleChange: (ev) ->
    updateHash @props.key, ev.target.value

Checkbox = React.createClass
  displayName: "CheckBox"

  render: ->
    React.DOM.fieldset null,
      React.DOM.label htmlFor: @props.id, @props.label
      React.DOM.input id: @props.id, type: "checkbox", name: @props.key, value: "yes", checked: @props.value is "yes", onChange: @handleChange

  handleChange: (ev) ->
    updateHash @props.key, if ev.target.checked then "yes" else "no"

################################################################################
# Adapted from https://github.com/guillaumervls/react-infinite-scroll
# Copyright (c) 2013 guillaumervls, MIT License
#
InfiniteScroll = React.createClass
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
  window.location.hash = "#" + ("#{k}=#{v}" for k, v of h).join("&")

boot = ->
  for id, book of bookData
    book.vpl_url = "http://vpl.bibliocommons.com#{book.vpl_url}"
    book.goodreads_url = "https://www.goodreads.com/book/show/#{book.goodreads_id}"
    book.available = book.availability is "Available"
    book.description = book.description.replace(/&?nbsp;?/g, " ") if book.description

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
