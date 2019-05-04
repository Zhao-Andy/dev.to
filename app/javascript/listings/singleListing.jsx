import PropTypes from 'prop-types';
import { h } from 'preact';

export const SingleListing = ({listing, onAddTag, currentUserId, onChangeCategory}) => {
  const tagLinks = listing.tag_list.map(tag => (
    <a href={`/listings?t=${tag}`} onClick={e => onAddTag(e, tag)} data-no-instant>{tag}</a>
  ));

  const editButton = currentUserId === listing.user_id ? <a href={`/listings/${listing.id}/edit`} className="classified-listing-edit-button">・edit</a> : <a href={`/report-abuse?url=https://dev.to/listings/${listing.category}/${listing.slug}`}>・report abuse</a>;

  const handleOpenModal = (e) => {
    e.preventDefault()
    window.history.pushState('', '', e.target.href)
    const overlayDiv = document.getElementById('listing-overlay')
    overlayDiv.style.display = 'block'
    overlayDiv.focus()
    overlayDiv.tabIndex = 0
  }

  const listingCard = () => {
    return(
      <div className="single-classified-listing">
        <div className="listing-content">
          <h3>
            <a href={`/listings/${listing.category}/${listing.slug}`} data-no-instant onClick={handleOpenModal}>
              {listing.title}
            </a>
          </h3>
          <div className="single-classified-listing-body" dangerouslySetInnerHTML={{ __html: listing.processed_html }} />
          <div className="single-classified-listing-tags">{tagLinks}</div>
          <div className="single-classified-listing-author-info">
            <a href={`/listings/${listing.category}`} onClick={e => onChangeCategory(e, listing.category)}>{listing.category}</a>
            ・
            <a href={`/${listing.author.username}`}>{listing.author.name}</a>
            {editButton}
          </div>
        </div>
      </div>
    )
  }

  return (
    listingCard()
  );
}

SingleListing.propTypes = {
  listing: PropTypes.object.isRequired,
  onAddTag: PropTypes.func.isRequired,
  onChangeCategory: PropTypes.func.isRequired,
  currentUserId: PropTypes.number,
};
